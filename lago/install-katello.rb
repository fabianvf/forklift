#!/usr/bin/env ruby

require 'English'
require 'open3'

HOST = "foreman.example.com"
CAPSULE = "capsule.example.com"

def syscall(*cmd)
  puts Dir.pwd
  puts cmd
  stdout, stderr, status = Open3.capture3(*cmd)
  if status.success?
    output = stdout.slice!(1..-(1 + $INPUT_RECORD_SEPARATOR.size))
    puts output
    return output
  else
    puts "ERROR: #{stdout}" unless stdout.empty?
    puts "ERROR: #{stderr}" unless stderr.empty?
    status.success?
  end
end

def execute_host(cmd)
  status = syscall("lago shell #{HOST} \"#{cmd}\"")
  exit(1) if status == false
  status
end

def execute_capsule(cmd)
  status = syscall("lago shell #{CAPSULE} \"#{cmd}\"")
  exit(1) if status == false
  status
end

def snapshot(snapshot)
  syscall("lago snapshot #{snapshot}")
end

def revert(snapshot)
  return unless syscall("lago status | grep 'Snapshots:'").include?(snapshot)
  syscall("lago revert #{snapshot}")
end

version = ARGV[0]

Dir.chdir("environment-#{version}") do
  execute_host('yum install -y net-tools')
  execute_capsule('yum install -y net-tools')

  host_ip_address = execute_host("ifconfig eth0 2>/dev/null|awk '/inet/ {print $2}'|sed 's/addr://'").split(" ")[1]
  capsule_ip_address = execute_capsule("ifconfig eth0 2>/dev/null|awk '/inet/ {print $2}'|sed 's/addr://'").split(" ")[1]

  execute_host("echo #{capsule_ip_address} capsule.example.com capsule >> /etc/hosts")
  execute_host("echo #{host_ip_address} foreman.example.com foreman >> /etc/hosts")

  execute_capsule("echo #{capsule_ip_address} capsule.example.com capsule >> /etc/hosts")
  execute_capsule("echo #{host_ip_address} foreman.example.com foreman >> /etc/hosts")

  execute_host("yum localinstall -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
  execute_host("yum localinstall -y http://yum.theforeman.org/nightly/el7/x86_64/foreman-release.rpm")
  execute_host("yum -y install foreman-release-scl")
  execute_host("yum localinstall -y http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm")
  execute_host("yum localinstall -y https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/RHEL/7/x86_64/katello-repos-latest.rpm")
  execute_host('yum -y update')
  execute_host('yum -y install katello')

  execute_host('katello-installer --foreman-admin-password changeme --foreman-oauth-consumer-secret foreman --foreman-oauth-consumer-key foreman --foreman-proxy-oauth-consumer-key foreman --foreman-proxy-oauth-consumer-secret foreman')

  execute_host("capsule-certs-generate --capsule-fqdn #{CAPSULE} --certs-tar ~/#{CAPSULE}.tar.gz")

  syscall("lago copy-from-vm #{HOST} '~/#{CAPSULE}.tar.gz' .")
  syscall("lago copy-to-vm #{CAPSULE} '#{CAPSULE}.tar.gz' '~/'")

  execute_capsule("yum localinstall -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
  execute_capsule("yum localinstall -y http://yum.theforeman.org/nightly/el7/x86_64/foreman-release.rpm")
  execute_capsule("yum -y install foreman-release-scl")
  execute_capsule("yum localinstall -y http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm")
  execute_capsule("yum localinstall -y https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/RHEL/7/x86_64/katello-repos-latest.rpm")
  execute_capsule('yum -y install capsule-installer')

  execute_capsule('capsule-installer --parent-fqdn "foreman.example.com"\
                    --foreman-base-url "https://foreman.example.com"\
                    --trusted-hosts "foreman.example.com"\
                    --register-in-foreman   "true"\
                    --oauth-consumer-key    "foreman"\
                    --oauth-consumer-secret "foreman"\
                    --pulp-oauth-secret     "foreman"\
                    --certs-tar             "/root/capsule.example.com.tar.gz"\
                    --puppet                "true"\
                    --puppetca              "true"')

  execute_capsule('yum -y localinstall http://foreman/pub/katello-ca-consumer-latest.noarch.rpm')
  execute_capsule('subscription-manager register --org "Default_Organization" --username admin --password changeme')
end
