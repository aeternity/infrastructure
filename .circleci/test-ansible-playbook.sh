#!/bin/bash

ansible-playbook -i localhost, \
  -e ansible_python_interpreter=/usr/bin/python3 \
  -e ansible_user=root -e ansible_ssh_pass=root "$@"

ansible-playbook -i localhost, \
  -e ansible_python_interpreter=/usr/bin/python3 \
  -e ansible_user=root -e ansible_ssh_pass=root "$@" \
  | grep -q 'changed=0.*failed=0' \
  && (echo 'Idempotence test: pass' && exit 0) \
  || (echo 'Idempotence test: fail' && exit 1)
