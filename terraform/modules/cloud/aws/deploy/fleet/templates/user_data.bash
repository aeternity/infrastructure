#!/bin/bash
# Don't enable debug mode in this script if secrets are managed as it ends-up in the logs
set -eo pipefail

exec > >(tee /tmp/user-data.log|logger -t user-data ) 2>&1

# Run Ansible in virtual environment
source /var/venv/bin/activate

# Dirty ugly hack to workaround missing python-apt in the virtualenv
# It cannot be (?!) installed in the virtualenv
# If --system-site-packages is used all the packages are copied and specifically python-cryptography
# Distro python-cryptography is OLD and if copied to the virtualenv,
# it prevents pip to installed newer package version for some reason,
# but ansible (paramico) does not work with the OLD One
cp -r /usr/lib/python3/dist-packages/apt* /var/venv/lib/python3.5/site-packages/

# Backward compatibility, passed by the Terraform template
bootstrap_version="${bootstrap_version}"

INSTANCE_ID=$(ec2metadata --instance-id)
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
WAIT_TIME=0
while [[ -z "$bootstrap_version" && $WAIT_TIME -lt 60 ]]; do
    bootstrap_version=$(aws ec2 describe-tags \
        --region=$REGION \
        --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=bootstrap_version" \
        --query 'Tags[0].Value' \
        --output=text \
    )
    sleep $WAIT_TIME
    let WAIT_TIME=WAIT_TIME+10
done

if [ ! -d "/infrastructure" ] ; then
    git clone -b $bootstrap_version --single-branch https://github.com/aeternity/infrastructure.git /infrastructure
else
    git -C /infrastructure fetch origin $bootstrap_version
    git -C /infrastructure reset --hard origin/$bootstrap_version
fi

bash /infrastructure/scripts/bootstrap.sh
