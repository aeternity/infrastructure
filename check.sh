#!/bin/bash

set -ev

openstack stack create test -e openstack/test/create.yml -t openstack/ae-environment.yml --enable-rollback --wait --dry-run

cd ansible
ansible-playbook --check -i localhost, -e 'ansible_python_interpreter="/usr/bin/env python"' environments.yml
ansible-lint setup1.yml
ansible-lint monitoring.yml
ansible-lint manage-node.yml
ansible-lint reset-net.yml
