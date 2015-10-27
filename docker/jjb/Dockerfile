FROM centos:centos7
MAINTAINER Katello Team <foreman-dev@googlegroups.com>

RUN yum install -y epel-release && yum clean all
RUN yum install -y git python-pip vim

RUN pip install virtualenv

RUN git clone https://github.com/openstack-infra/jenkins-job-builder.git

WORKDIR jenkins-job-builder

RUN git remote add foreman https://github.com/theforeman/jenkins-job-builder.git
RUN git fetch foreman
RUN git config user.name "Foo Bar"
RUN git config user.email "foor@bar.foo"
RUN git cherry-pick d95d0ae5ede11a16591fcde02d2821ab3d2479ee

RUN virtualenv jjb
RUN source jjb/bin/activate
RUN easy_install .

WORKDIR /
