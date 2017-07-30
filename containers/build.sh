#!/bin/bash

if [[ -z "$1" ]];then
  ansible-container --devel build --roles-path roles/ ../roles
else
  ansible-container --devel build --roles-path roles/ ../roles --services $@
fi
