#!/bin/bash
cd ansible && ansible-playbook -i ssh, \
  -e ansible_python_interpreter=/usr/bin/python3 \
  -e ansible_user=root -e ansible_ssh_pass=root "$@"
