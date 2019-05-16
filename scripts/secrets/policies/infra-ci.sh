VAULT_SECRETS_ROLE=${VAULT_SECRETS_ROLE:-ae-fleet-manager}

source ${DIR}/policies/ci.sh

ROCKET_HOOK_DEVOPS_URL=$(vault read -field=core-alerts-devops secret/rocketchat/prod/hooks)

dump_var "ROCKET_HOOK_DEVOPS_URL"
