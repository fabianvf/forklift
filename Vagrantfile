require "yaml"

VAGRANTFILE_API_VERSION = "2"

bats_shell = "/vagrant/bats/bootstrap_vagrant.sh"
install_shell = "yum -y install ruby && cd /vagrant && ./setup.rb "

base_boxes = {
  :centos6 => {
    :box_name => 'centos6',
    :image_name => /CentOS 6\.5/,
    :default => true,
    :pty => true,
    :synced_folder => '.',
    :memory => 3560,
    :cpus => 2,
    :virtualbox => 'http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130731.box',
    :libvirt => 'http://m0dlx.com/files/foreman/boxes/centos64.box'
  },
  :centos7 => {
    :box_name => 'centos7',
    :image_name => /CentOS 7/,
    :default => true,
    :pty => true,
    :synced_folder => '.',
    :memory => 3560,
    :cpus => 2,
    :libvirt => 'https://download.gluster.org/pub/gluster/purpleidea/vagrant/centos-7.0/centos-7.0.box'
  },
}

boxes = [
  {:name => 'centos6', :shell => "#{install_shell} centos6"}.merge(base_boxes[:centos6]),
  {:name => 'centos6-2.0', :shell => "#{install_shell} centos6 --version=2.0"}.merge(base_boxes[:centos6]),
  {:name => 'centos6-bats', :shell => bats_shell}.merge(base_boxes[:centos6]),
  {:name => 'centos6-devel', :shell => "#{install_shell} centos6 --devel"}.merge(base_boxes[:centos6]),
  {:name => 'centos7', :shell => "#{install_shell} centos7"}.merge(base_boxes[:centos7]),
  {:name => 'centos7-2.0', :shell => "#{install_shell} centos7 --version=2.0"}.merge(base_boxes[:centos7]),
  {:name => 'centos7-bats', :shell => bats_shell}.merge(base_boxes[:centos7]),
  {:name => 'centos7-devel', :shell => "#{install_shell} centos7 --devel"}.merge(base_boxes[:centos7]),
]

custom_boxes = File.exists?('boxes.yaml') ? YAML::load(File.open('boxes.yaml')) : {}

Dir.glob("plugins/**/boxes.yaml").each do |plugin|
  plugin_boxes = YAML::load(File.open(plugin))
  plugin_boxes.each { |name, box| box['synced_folder'] = File.dirname(plugin) }
  custom_boxes = custom_boxes.merge(plugin_boxes)
end

custom_boxes.each do |name, args|
  if (box = boxes.find { |box| box[:name] == args['box'] })
    definition = box.merge(:name => name)

    definition[:shell] += " #{args['options']} " if args['options']
    definition[:shell] += " --installer-options='#{args['installer']}' " if args['installer']
    definition[:shell] = args['shell'] if args['shell']
    definition[:synced_folder] = args['synced_folder'] if args['synced_folder']
    definition[:memory] = args['memory'] if args['memory']
    definition[:cpus] = args['cpus'] if args['cpus']

    boxes << definition
  else
    box = {:name => name, :shell => install_shell}
    box = box.merge(args)

    boxes << box
  end
end

# Turn hash keys into symbols
boxes = boxes.collect { |box| Hash[box.map { |(k,v)| [k.to_sym,v] }] }

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  boxes.each do |box|
    config.vm.define box[:name], primary: box[:default] do |machine|
      machine.vm.box = box[:box_name]
      machine.vm.hostname = "katello-#{box[:name]}.example.com"

      machine.vm.provision :shell do |shell|
        shell.inline = box[:shell]
      end

      config.vm.provider :libvirt do |provider, override|
        override.vm.box_url = box[:libvirt]
        override.vm.synced_folder box[:synced_folder], "/vagrant", type: "rsync"

        provider.memory = box[:memory]
        provider.cpus = box[:cpus]
      end

      machine.vm.provider :rackspace do |provider, override|
        provider.vm.box = 'dummy'
        provider.server_name = machine.vm.hostname
        provider.flavor = /4GB/
        provider.image = box[:image_name]
        provider.ssh.pty = true if box[:pty]
      end

      config.vm.provider :virtualbox do |provider, override|
        override.vm.box_url = box[:virtualbox]

        provider.memory = box[:memory]
        provider.cpus = box[:cpus]

        provider.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
        provider.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]

        if box[:name].include?('devel')
          override.vm.network :forwarded_port, guest: 3000, host: 3330
          override.vm.network :forwarded_port, guest: 443, host: 4430
        else
          override.vm.network :forwarded_port, guest: 80, host: 8080
          override.vm.network :forwarded_port, guest: 443, host: 4433
        end
      end

    end
  end

end
