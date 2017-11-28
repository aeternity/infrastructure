#!/bin/bash

set -ev

# Free Travis version does not support SSH key pairs, thus using encrypted files for SSH deploy key
# https://docs.travis-ci.com/user/encrypting-files/
openssl aes-256-cbc -K $encrypted_989f4ea822a6_key -iv $encrypted_989f4ea822a6_iv -in ansible/files/travis/master_key.enc -out /tmp/master_rsa -d
chmod 600 /tmp/master_rsa
eval "$(ssh-agent -s)"
ssh-add /tmp/master_rsa

# Unfortunately the callback does not support environment vars but only config
echo "api_key: ${datadog_api_key:?}" > ansible/callback_plugins/datadog_callback.yml

# Setup environments and all epoch nodes with Ansible
cd ansible
ansible-galaxy install -r requirements.yml
ansible-playbook environments.yml
ansible-playbook --limit=epoch setup.yml
ansible-playbook --limit="integration:uat:&epoch" --extra-vars "datadog_api_key=${datadog_api_key:?}" monitoring.yml
