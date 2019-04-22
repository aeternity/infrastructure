#!/bin/bash
# Don't enable debug mode in this script if secrets are managed as it ends-up in the logs
set -eo pipefail

exec > >(tee /tmp/user-data.log|logger -t user-data ) 2>&1

bash <(curl -s https://raw.githubusercontent.com/aeternity/infra-node-aws-bootstrap/master/bootstrap.sh)
