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

cd $(dirname $0)/../ansible/

# Temporary fix/workaround for non-executable vault install
chmod +x /usr/bin/vault

# Authenticate the instance to CSM
PKCS7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')

export VAULT_ADDR=$vault_addr
if [ -f "/root/.vault_nonce" ] ; then
    export NONCE=$(cat /root/.vault_nonce)
else
    export NONCE=$(vault write auth/aws/login pkcs7=$PKCS7 role=$vault_role | grep token_meta_nonce | awk '{print $2}')
    echo $NONCE > /root/.vault_nonce
    chmod 0600 /root/.vault_nonce
fi

export VAULT_TOKEN=$(vault write -field=token auth/aws/login pkcs7=$PKCS7 role=$vault_role nonce=$NONCE)

# Run Ansible in virtual environment
source /var/venv/bin/activate

# Install ansible roles
ansible-galaxy install -r requirements.yml

# Dirty ugly hack to workaround missing python-apt in the virtualenv
# It cannot be (?!) installed in the virtualenv
# If --system-site-packages is used all the packages are copied and specifically python-cryptography
# Distro python-cryptography is OLD and if copied to the virtualenv,
# it prevents pip to installed newer package version for some reason,
# but ansible (paramico) does not work with the OLD One
cp -r /usr/lib/python3/dist-packages/apt* /var/venv/lib/python3.5/site-packages/

# Create temporary inventory just because of the group_vars
cat > /tmp/local_inventory << EOF
[local]
localhost ansible_connection=local

[tag_role_epoch:children]
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
    setup.yml

ansible-playbook \
    -i /tmp/local_inventory \
    -e ansible_python_interpreter=$(which python3) \
    -e env=${env} \
    monitoring.yml

ansible-playbook \
    -i /tmp/local_inventory \
    -e ansible_python_interpreter=$(which python3) \
    --become-user epoch -b \
    -e package=${epoch_package} \
    -e env=${env} \
    -e db_version=0 \
    deploy.yml
