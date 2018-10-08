#!/bin/bash

ansible-playbook -i localhost, -c local "$@"
ansible-playbook -i localhost, -c local "$@" \
| grep -q 'changed=0.*failed=0' \
&& (echo 'Idempotence test: pass' && exit 0) \
|| (echo 'Idempotence test: fail' && exit 1)
