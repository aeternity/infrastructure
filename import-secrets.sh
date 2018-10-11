#!/bin/bash
set -e

if [ -n "$VAULT_GITHUB_TOKEN" ]; then
    export VAULT_TOKEN=$(vault login -field=token -method=github token=$VAULT_GITHUB_TOKEN)
fi

if [ -n "$VAULT_ROLE_ID" -a -n "$VAULT_SECRET_ID" ]; then
    export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=$VAULT_ROLE_ID secret_id=$VAULT_SECRET_ID)
fi

# Additional variable with empty check until docker fix is released
# https://github.com/docker/cli/pull/1019
if [ -n "$VAULT_AUTH_TOKEN" ]; then
    export VAULT_TOKEN=$VAULT_AUTH_TOKEN
fi

if [ -n "$VAULT_TOKEN" ]; then
    export DATADOG_API_KEY=$(vault read -field=api_key secret/datadog/deploy)
fi
