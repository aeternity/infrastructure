#!/bin/bash

set -ev

openstack stack create test -e openstack/test/create.yml -t openstack/ae-environment.yml --enable-rollback --wait --dry-run

cd ansible
ansible-playbook --check -i localhost, environments.yml
ansible-lint setup.yml
ansible-lint monitoring.yml
ansible-lint manage-node.yml
ansible-lint reset-net.yml
