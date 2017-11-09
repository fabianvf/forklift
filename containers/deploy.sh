#!/bin/bash

config=configs/platform.yml

if [ ! -z $@ ]; then
  config=$@
fi

ansible-playbook deploy.yml -e deployment_config=$config
#ansible-playbook ansible-deployment/foreman.yml --tags start
