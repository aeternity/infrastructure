#!/usr/bin/env bash

set -e

CREDS_ROLE="${CREDS_ROLE:-ae-inventory}"
VAULT_SECRETS_ROLE="${VAULT_SECRETS_ROLE:-$CREDS_ROLE}"
AE_VAULT_TOKENS_TTL=${AE_VAULT_TOKENS_TTL:-4h}

VAULT_ADDR=${VAULT_ADDR:-$AE_VAULT_ADDR}
VAULT_GITHUB_TOKEN=${VAULT_GITHUB_TOKEN:-$AE_VAULT_GITHUB_TOKEN}
VAULT_AUTH_TOKEN=${VAULT_AUTH_TOKEN:-$AE_VAULT_AUTH_TOKEN}
VAULT_TOKENS_TTL=${VAULT_TOKENS_TTL:-$AE_VAULT_TOKENS_TTL}

export GITHUB_TOKEN=${GITHUB_TOKEN:-$VAULT_GITHUB_TOKEN}

if [ -n "$VAULT_ADDR" ]; then
    export VAULT_ADDR
fi

if [ -n "$VAULT_GITHUB_TOKEN" ]; then
    export VAULT_TOKEN=$(vault login -field=token -method=github token=$VAULT_GITHUB_TOKEN)
    vault token renew -increment=${VAULT_TOKENS_TTL} > /dev/null 2>&1
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
    AWS_CREDS=$(vault write -f aws/sts/${VAULT_SECRETS_ROLE} ttl=${VAULT_TOKENS_TTL})
    export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDS | grep -o 'access_key [^ ]*' | awk '{print $2}')
    export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDS | grep -o 'secret_key [^ ]*' | awk '{print $2}')
    export AWS_SESSION_TOKEN=$(echo $AWS_CREDS | grep -o 'security_token [^ ]*' | awk '{print $2}')

    export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.gcp.json
    vault read -field json secret/google/${VAULT_SECRETS_ROLE} > $GOOGLE_APPLICATION_CREDENTIALS

    export GITHUB_API_TOKEN=$(vault read -field=value secret/github/prod/token)

    if [ "$VAULT_SECRETS_ROLE" = "ae-fleet-manager" ]; then
        DOCKERHUB_CREDS=$(vault read secret/dockerhub/prod)
        export DOCKER_USER=$(echo $DOCKERHUB_CREDS | grep -o 'username [^ ]*' | awk '{print $2}')
        export DOCKER_PASS=$(echo $DOCKERHUB_CREDS | grep -o 'password [^ ]*' | awk '{print $2}')

        export ROCKET_HOOK_URL=$(vault read -field=core-alerts secret/rocketchat/prod/hooks)
        export ROCKET_HOOK_DEVOPS_URL=$(vault read -field=core-alerts-devops secret/rocketchat/prod/hooks)
    fi
fi
