#!/usr/bin/env bash

set -eo pipefail

###
### Install EC2 connect
###

apt-get update
apt-get install -y ec2-instance-connect

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
bootstrap_config=$(echo $AWS_TAGS | jq -r '.[] | select(.Key == "bootstrap_config") | .Value')
aerole=$(echo $AWS_TAGS | jq -r '.[] | select(.Key == "role") | .Value')

###
### Vault - Authenticate the instance to CSM
###

# Vault requires the instance to be in running state in order to authenticate it
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region=$AWS_REGION

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
    ANSIBLE_VARS="@/tmp/node_config.yml"
fi

if [[ -n "${bootstrap_config}" && "${bootstrap_config}" != "none" ]]; then
    vault read -field=ansible_vars ${bootstrap_config} > /tmp/ansible_vars.yml
    ANSIBLE_VARS="@/tmp/ansible_vars.yml"
fi

###
### Temporary workaround to support old AMIs that include old ansible
###

pip3 uninstall -y ansible
pip3 install ansible==4.10.0

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
    -e ${ANSIBLE_VARS} \
    setup.yml \
    monitoring.yml

if [[ -n "${aerole}" && "${aerole}" = "aenode" ]]; then
    ansible-playbook \
        -i localhost, -c local \
        -e ansible_python_interpreter=$(which python3) \
        --become-user aeternity -b \
        -e ${ANSIBLE_VARS} \
        deploy.yml \
        mnesia_snapshot_restore.yml
fi

if [[ -n "${aerole}" && "${aerole}" = "aemdw" ]]; then
    ansible-playbook \
        -i localhost, -c local \
        -e ansible_python_interpreter=$(which python3) \
        --become-user ubuntu -b \
        -e ${ANSIBLE_VARS} \
        deploy-aemdw.yml
fi
