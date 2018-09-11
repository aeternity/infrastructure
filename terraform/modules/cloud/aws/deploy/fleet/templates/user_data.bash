#!/bin/bash

# Don't enable debug mode in this script if secrets are managed as it ends-up in the logs
# set -x
exec > >(tee /tmp/user-data.log|logger -t user-data ) 2>&1

export INFRASTRUCTURE_ANSIBLE_VAULT_PASSWORD=`aws --region ${region} secretsmanager get-secret-value --secret-id ansible_vault_password --output text --query 'SecretString'`

git clone -b master --single-branch https://github.com/aeternity/infrastructure.git /infrastructure
cd /infrastructure/ansible

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
    -i inventory/vault.yml \
    -i /tmp/local_inventory \
    -e env=${env} \
    monitoring.yml

ansible-playbook \
    -i inventory/vault.yml \
    -i /tmp/local_inventory \
    --become-user epoch -b \
    -e package=${epoch_package} \
    -e env=${env} \
    -e db_version=0 \
    deploy.yml
