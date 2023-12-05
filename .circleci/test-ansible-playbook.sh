#!/usr/bin/env bash

ansible-playbook -i aenode, \
  -e ansible_python_interpreter=/usr/bin/python3 \
  -e ansible_user=root -e ansible_ssh_pass=root "$@"

tempfile="/tmp/playbook-out-$(basename $1)-$(date +%s)"
touch $tempfile

ansible-playbook -i aenode, \
  -e ansible_python_interpreter=/usr/bin/python3 \
  -e ansible_user=root -e ansible_ssh_pass=root "$@" \
  | tee $tempfile \
  | grep -q 'changed=0.*failed=0' \
  && (echo 'Idempotence test: pass' && exit 0) \
  || (cat $tempfile && echo 'Idempotence test: fail' && exit 1)
