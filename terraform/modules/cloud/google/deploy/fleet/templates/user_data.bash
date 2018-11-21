#!/bin/bash

# Don't enable debug mode in this script if secrets are managed as it ends-up in the logs
# set -x
exec > >(tee /tmp/user-data.log|logger -t user-data ) 2>&1

git clone -b ${bootstrap_version} --single-branch https://github.com/aeternity/infrastructure.git /infrastructure
cd /infrastructure/ansible

# Temporary fix/workaround for non-executable vault install
chmod +x /usr/bin/vault

# Authenticate the instance to CSM
PKCS7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')
export VAULT_ADDR=${vault_addr}
export VAULT_TOKEN=$(vault write -field=token auth/aws/login pkcs7=$PKCS7 role=${vault_role})

# Install ansible roles
ansible-galaxy install -r requirements.yml

# Create temporary inventory just because of the group_vars
cat > /tmp/local_inventory << EOF
[local]
localhost ansible_connection=local

[tag_role_epoch:children]
local

[tag_env_${env}:children]
local

EOF

ansible-playbook \
    -i /tmp/local_inventory \
    -e env=${env} \
    monitoring.yml

ansible-playbook \
    -i /tmp/local_inventory \
    --become-user epoch -b \
    -e package=${epoch_package} \
    -e env=${env} \
    -e db_version=0 \
    deploy.yml
