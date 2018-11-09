#!/bin/bash
set -e

AWS_CREDS_ROLE="${AWS_CREDS_ROLE:-epoch-fleet-manager}"
CREDS_ROLE="${CREDS_ROLE:-$AWS_CREDS_ROLE}"

VAULT_ADDR=${VAULT_ADDR:-$AE_VAULT_ADDR}
VAULT_GITHUB_TOKEN=${VAULT_GITHUB_TOKEN:-$AE_VAULT_GITHUB_TOKEN}

# Vault address secret used by Terraform, because it cannot be sources in TF
if [ -n "$VAULT_ADDR" ]; then
    export TF_VAR_vault_addr=$VAULT_ADDR
fi

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
    AWS_CREDS=$(vault write -f aws/sts/${CREDS_ROLE})
    export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDS | grep -o 'access_key [^ ]*' | awk '{print $2}')
    export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDS | grep -o 'secret_key [^ ]*' | awk '{print $2}')
    export AWS_SESSION_TOKEN=$(echo $AWS_CREDS | grep -o 'security_token [^ ]*' | awk '{print $2}')

    export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.gcp.json
    vault read -field json secret/google/${CREDS_ROLE} > $GOOGLE_APPLICATION_CREDENTIALS

    DOCKERHUB_CREDS=$(vault read secret/dockerhub/prod)
    export DOCKER_USER=$(echo $DOCKERHUB_CREDS | grep -o 'username [^ ]*' | awk '{print $2}')
    export DOCKER_PASS=$(echo $DOCKERHUB_CREDS | grep -o 'password [^ ]*' | awk '{print $2}')

    export DATADOG_API_KEY=$(vault read -field=api_key secret/datadog/deploy)
    export ROCKET_HOOK_URL=$(vault read -field=core-alerts secret/rocketchat/prod/hooks)
fi
