#!/bin/bash
set -Eeuo pipefail

AE_VAULT_ADDR=${AE_VAULT_ADDR:-}
AE_VAULT_GITHUB_TOKEN=${AE_VAULT_GITHUB_TOKEN:-}
AE_VAULT_AUTH_TOKEN=${AE_VAULT_AUTH_TOKEN:-}
AE_VAULT_TOKENS_TTL=${AE_VAULT_TOKENS_TTL:-4h}

VAULT_ADDR=${VAULT_ADDR:-$AE_VAULT_ADDR}
VAULT_GITHUB_TOKEN=${VAULT_GITHUB_TOKEN:-$AE_VAULT_GITHUB_TOKEN}
VAULT_AUTH_TOKEN=${VAULT_AUTH_TOKEN:-$AE_VAULT_AUTH_TOKEN}
VAULT_TOKENS_TTL=${VAULT_TOKENS_TTL:-$AE_VAULT_TOKENS_TTL}

if [ -n "$VAULT_ADDR" ]; then
    export VAULT_ADDR
fi

if [ -n "$VAULT_GITHUB_TOKEN" ]; then
    export VAULT_TOKEN=$(vault login -field=token -method=github token=$VAULT_GITHUB_TOKEN)
    vault token renew -increment=${VAULT_TOKENS_TTL} > /dev/null 2>&1
fi

if [ -n "${VAULT_ROLE_ID:-}" -a -n "${VAULT_SECRET_ID:-}" ]; then
    export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=$VAULT_ROLE_ID secret_id=$VAULT_SECRET_ID)
fi

# Additional variable with empty check until docker fix is released
# https://github.com/docker/cli/pull/1019
if [ -n "$VAULT_AUTH_TOKEN" ]; then
    export VAULT_TOKEN=$VAULT_AUTH_TOKEN
fi
