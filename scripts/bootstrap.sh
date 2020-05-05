#!/usr/bin/env bash

set -eo pipefail

###
#### Receive bootstrap configuration from AWS
###

INSTANCE_ID=$(ec2metadata --instance-id)
AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
AWS_TAGS='[]'

# Pull AWS tags until available. Retries in 10s intervals total 150s
WAIT_TIME=0
while [[ $AWS_TAGS == '[]' && $WAIT_TIME -lt 60 ]]; do
    AWS_TAGS=$(aws ec2 describe-tags \
      --region=$AWS_REGION \
      --filters "Name=resource-id,Values=$INSTANCE_ID" \
      --query 'Tags' \
    )
    sleep $WAIT_TIME
    let WAIT_TIME=WAIT_TIME+10
done

vault_addr=$(echo $AWS_TAGS | jq -r '.[] | select(.Key == "vault_addr") | .Value')
vault_role=$(echo $AWS_TAGS | jq -r '.[] | select(.Key == "vault_role") | .Value')
node_config=$(echo $AWS_TAGS | jq -r '.[] | select(.Key == "node_config") | .Value')

###
### Vault - Authenticate the instance to CSM
###

PKCS7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')

export VAULT_ADDR=$vault_addr
if [ -f "/root/.vault_nonce" ] ; then
    export NONCE=$(cat /root/.vault_nonce)
else
    export NONCE=$(vault write auth/aws/login pkcs7=$PKCS7 role=$vault_role | grep token_meta_nonce | awk '{print $2}')
    if [ -z "$NONCE" ]; then
        echo "NONCE is empty"
        exit 1
    fi

    echo $NONCE > /root/.vault_nonce
    chmod 0600 /root/.vault_nonce
fi

export VAULT_TOKEN=$(vault write -field=token auth/aws/login pkcs7=$PKCS7 role=$vault_role nonce=$NONCE)

###
### Dynamic node config
###

# Override the env defaults with ones stored in $vault_config
if [[ -n "${node_config}" && "${node_config}" != "none" ]]; then
    vault read -field=node_config ${node_config} > /tmp/node_config.yml
fi

###
### Bootstrap the instance with Ansible playbooks
###

cd $(dirname $0)/../ansible
ansible-galaxy install -r requirements.yml

# While Ansible is run by Python 3 because of the virtual environment
# the "remote" (which is in this case the same) host interpreter must also be set to python3
# in this case it's the path in the virtual environment on the controller (same as the remote)
# thus the which command usage.
# It must be absolute because of the virtualenv, otherwise it will use the system Python 3
ansible-playbook \
    -i localhost, -c local \
    -e ansible_python_interpreter=$(which python3) \
    -e vault_addr=${vault_addr} \
    -e "@/tmp/node_config.yml" \
    setup.yml \
    monitoring.yml

# Keep db_version in sync with the value in file deployment/DB_VERSION from aeternity/aeternity repo!
ansible-playbook \
    -i localhost, -c local \
    -e ansible_python_interpreter=$(which python3) \
    --become-user aeternity -b \
    -e "@/tmp/node_config.yml" \
    deploy.yml \
    mnesia_snapshot_restore.yml
