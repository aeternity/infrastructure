#!/bin/bash
set -x
exec > >(tee /tmp/user-data.log|logger -t user-data ) 2>&1

#SETTING UP HOSTNAME

REGION="${region}"
IP=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
echo "aws-$REGION-$IP" > /etc/hostname
hostname "aws-$REGION-$IP"

#SETUP DATADOG

MEM=$(awk '/MemTotal/ {printf("%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
FLAVOR="c$(nproc).m$MEM"
DATADOG_API_KEY=`aws --region ${region} secretsmanager get-secret-value --secret-id datadog_api_key  | jq '.SecretString | fromjson | .datadog_api_key'`

sed -i -- "s/DATADOG_API_KEY/$DATADOG_API_KEY/g" /etc/datadog-agent/datadog.yaml
sed -i -- "s/region:unknown/region:${region}/g" /etc/datadog-agent/datadog.yaml
sed -i -- "s/color:unknown/color:${color}/g" /etc/datadog-agent/datadog.yaml
sed -i -- "s/env:unknown/env:${env}/g" /etc/datadog-agent/datadog.yaml
sed -i -- "s/flavor:.*$/flavor:$FLAVOR/g" /etc/datadog-agent/datadog.yaml
sed -i -- "s/127.0.0.1:3013/$IP:3013/g" /etc/datadog-agent/conf.d/http_check.d/conf.yaml

sudo service datadog-agent start

#INSTALL EPOCH

VERSION="${epoch_version}"

FILE="epoch-$VERSION-ubuntu-x86_64.tar.gz"
URL="https://github.com/aeternity/epoch/releases/download/v$VERSION/$FILE"

wget -q $URL -O /home/epoch/$FILE

mkdir /home/epoch/node
tar -xf /home/epoch/$FILE -C /home/epoch/node
chown -R epoch:epoch /home/epoch/node

cat > /home/epoch/node/epoch.yaml << EOF
---
chain:
    persist: true

mining:
    autostart: true
    beneficiary: "${epoch_beneficiary}"

logging:
    level: warning

EOF

sudo su -c "/home/epoch/node/bin/epoch start" epoch
