#!/usr/bin/env bash

set -Eeuo pipefail

SECRETS_OUTPUT_DIR=${SECRETS_OUTPUT_DIR:-/secrets}
# Full path of this script
SCRIPT_PATH=`readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo $0`
# Full path of this script directory
DIR=`dirname $SCRIPT_PATH`

source ${DIR}/authenticate.sh

# Early exit if in non-authenticated environment
if [ -z "${VAULT_TOKEN:-}" ]; then
    echo "Not authenticated (no VAULT_TOKEN). Won't dump secrets."
    exit 0
fi

function dump_var {
    echo ${!1} > $SECRETS_OUTPUT_DIR/${1:?}
    echo "Written:" $SECRETS_OUTPUT_DIR/${1:?}
}

mkdir -p $SECRETS_OUTPUT_DIR

# Dump based on Vault (token) policy
POLICY=$(vault token lookup -format=json | jq -r '.data.policies | .[]' | grep -v default)
POLICY_FILE=${DIR}/policies/$POLICY.sh
if [ -e $POLICY_FILE ]; then
    source $POLICY_FILE
fi
