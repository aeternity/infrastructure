#!/bin/bash

for i in "$@"
do
case $i in
    --vault_addr=*)
    vault_addr="${i#*=}"
    shift # past argument=value
    ;;
    --vault_role=*)
    vault_role="${i#*=}"
    shift # past argument=value
    ;;
    --env=*)
    env="${i#*=}"
    shift # past argument=value
    ;;
    --epoch_package=*)
    epoch_package="${i#*=}"
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

cd /infrastructure/ansible
# Temporary fix/workaround for non-executable vault install
chmod +x /usr/bin/vault

# Authenticate the instance to CSM
PKCS7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')

export VAULT_ADDR=$vault_addr
export VAULT_TOKEN=$(vault write -field=token auth/aws/login pkcs7=$PKCS7 role=$vault_role)

export env=$env
export epoch_package=$epoch_package

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