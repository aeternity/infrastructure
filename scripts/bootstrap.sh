#!/bin/bash
# Do not run after first error
set -eo pipefail

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
    --aeternity_package=*)
    aeternity_package="${i#*=}"
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

# Backward compatibility with user_data that does not activate the environment
if [ -z $VIRTUAL_ENV ]; then
    # Run Ansible in virtual environment
    source /var/venv/bin/activate

    # Dirty ugly hack to workaround missing python-apt in the virtualenv
    # It cannot be (?!) installed in the virtualenv
    # If --system-site-packages is used all the packages are copied and specifically python-cryptography
    # Distro python-cryptography is OLD and if copied to the virtualenv,
    # it prevents pip to installed newer package version for some reason,
    # but ansible (paramico) does not work with the OLD One
    cp -r /usr/lib/python3/dist-packages/apt* /var/venv/lib/python3.5/site-packages/
fi

# Fetch parameters from EC2 tags if not provided by the caller
# Legacy instance configuration pass those parameters in user_data
# To be removed when legacy instances are out
if [[ -z "$vault_addr" || -z "$vault_role" || -z "$env" || -z "$aeternity_package" ]]; then
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
    env=$(echo $AWS_TAGS | jq -r '.[] | select(.Key == "env") | .Value')
    aeternity_package=$(echo $AWS_TAGS | jq -r '.[] | select(.Key == "package") | .Value')
fi

# Temporary fix/workaround for non-executable vault install
chmod +x /usr/bin/vault

# Authenticate the instance to CSM
PKCS7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')

RESTORE_DATABASE=false

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

    RESTORE_DATABASE=true
fi

export VAULT_TOKEN=$(vault write -field=token auth/aws/login pkcs7=$PKCS7 role=$vault_role nonce=$NONCE)

cd $(dirname $0)/../ansible/

# Install ansible roles
ansible-galaxy install -r requirements.yml

# Create temporary inventory just because of the group_vars
cat > /tmp/local_inventory << EOF
[local]
localhost ansible_connection=local

[tag_role_aenode:children]
local

[tag_env_${env}:children]
local

EOF

# While Ansible is run by Python 3 because of the virtual environment
# the "remote" (which is in this case the same) host interpreter must also be set to python3
# in this case it's the path in the virtual environment on the controller (same as the remote)
# thus the which command usage.
# It must be absolute because of the virtualenv, otherwise it will use the system Python 3
ansible-playbook \
    -i /tmp/local_inventory \
    -e ansible_python_interpreter=$(which python3) \
    -e env=${env} \
    setup.yml

ansible-playbook \
    -i /tmp/local_inventory \
    -e ansible_python_interpreter=$(which python3) \
    -e env=${env} \
    monitoring.yml

# Keep db_version in sync with the value in file deployment/DB_VERSION from aeternity/aeternity repo!
ansible-playbook \
    -i /tmp/local_inventory \
    -e ansible_python_interpreter=$(which python3) \
    --become-user aeternity -b \
    -e package=${aeternity_package} \
    -e env=${env} \
    -e db_version=1 \
    deploy.yml

RESTORE_ENV=${env}
if [ "$env" = "api_main" ] ; then
    RESTORE_ENV=main
fi

if [ "$RESTORE_DATABASE" = true ] ; then
    if [ "$RESTORE_ENV" = "main" ] || [ "$RESTORE_ENV" == "uat" ] ; then # restore only main / uat

        ansible-playbook \
            -i /tmp/local_inventory \
            -e ansible_python_interpreter=$(which python3) \
            --become-user aeternity -b \
            -e env=${RESTORE_ENV} \
            -e db_version=1 \
            mnesia_snapshot_restore.yml
    fi
fi
