#!/bin/bash
# Don't enable debug mode in this script if secrets are managed as it ends-up in the logs
# set -x
exec > >(tee /tmp/user-data.log|logger -t user-data ) 2>&1

if [ ! -d "/infrastructure" ] ; then
    git clone -b ${bootstrap_version} --single-branch https://github.com/aeternity/infrastructure.git /infrastructure
else
    git -C /infrastructure pull origin ${bootstrap_version}
fi

bash /infrastructure/scripts/bootstrap.sh \
     --vault_addr=${vault_addr} \
     --vault_role=${vault_role} \
     --env=${env} \
     --epoch_package=${epoch_package}
