VAULT_SECRETS_ROLE=${VAULT_SECRETS_ROLE:-ae-inventory}

source ${DIR}/policies/ci.sh

ROCKET_HOOK_URL=$(vault read -field=core-alerts secret/rocketchat/prod/hooks)

dump_var "ROCKET_HOOK_URL"
