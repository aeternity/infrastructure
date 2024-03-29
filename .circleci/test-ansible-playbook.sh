#!/usr/bin/env bash

PLAYBOOK_HOST=${PLAYBOOK_HOST:-aenode}

ansible-playbook -i ${PLAYBOOK_HOST:?}, \
  -e ansible_python_interpreter=/usr/bin/python3 \
  -e ansible_user=root -e ansible_ssh_pass=root "$@"

tempfile="/tmp/playbook-out-$(basename $1)-$(date +%s)"
touch $tempfile

ansible-playbook -i ${PLAYBOOK_HOST:?}, \
  -e ansible_python_interpreter=/usr/bin/python3 \
  -e ansible_user=root -e ansible_ssh_pass=root "$@" \
  | tee $tempfile \
  | grep -q 'changed=0.*failed=0' \
  && (echo 'Idempotence test: pass' && exit 0) \
  || (cat $tempfile && echo 'Idempotence test: fail' && exit 1)
