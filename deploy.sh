#!/bin/bash

set -ev

# Free Travis version does not support SSH key pairs, thus using encrypted files for SSH deploy key
# https://docs.travis-ci.com/user/encrypting-files/
openssl aes-256-cbc -K $encrypted_989f4ea822a6_key -iv $encrypted_989f4ea822a6_iv -in ansible/files/travis/master_key.enc -out master_key -d
chmod 600 /tmp/deploy_rsa
eval "$(ssh-agent -s)"
ssh-add /tmp/deploy_rsa

# Setup all epoch nodes with Ansible
cd ansible && ansible-playbook --limit=epoch setup.yml
