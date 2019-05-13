#!/bin/bash
set -Eeuo pipefail

VAULT_SECRETS_ROLE=${VAULT_SECRETS_ROLE:-ae-images}

source ${DIR}/policies/ci.sh
