#!/bin/bash
set -e

AWS_CREDS_ROLE="${AWS_CREDS_ROLE:-epoch-fleet-manager}"

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
    AWS_CREDS=$(vault read aws/creds/${AWS_CREDS_ROLE})
    export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDS | grep -o 'access_key [^ ]*' | awk '{print $2}')
    export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDS | grep -o 'secret_key [^ ]*' | awk '{print $2}')
    DOCKERHUB_CREDS=$(vault read secret/dockerhub/prod)
    export DOCKER_USER=$(echo $DOCKERHUB_CREDS | grep -o 'username [^ ]*' | awk '{print $2}')
    export DOCKER_PASS=$(echo $DOCKERHUB_CREDS | grep -o 'password [^ ]*' | awk '{print $2}')
    export DATADOG_API_KEY=$(vault read -field=api_key secret/datadog/deploy)
    export ROCKET_HOOK_URL=$(vault read -field=core-alerts secret/rocketchat/prod/hooks)

    # AWS dynamic credentials are eventually consistent - add a delay
    # https://www.vaultproject.io/docs/secrets/aws/index.html#usage
    sleep 10
fi
