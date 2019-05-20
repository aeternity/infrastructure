VAULT_SECRETS_ROLE=${VAULT_SECRETS_ROLE:-ae-inventory}

AWS_CREDS=$(vault write -f aws/sts/${VAULT_SECRETS_ROLE} ttl=${VAULT_TOKENS_TTL})
AWS_ACCESS_KEY_ID=$(echo $AWS_CREDS | grep -o 'access_key [^ ]*' | awk '{print $2}')
AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDS | grep -o 'secret_key [^ ]*' | awk '{print $2}')
AWS_SESSION_TOKEN=$(echo $AWS_CREDS | grep -o 'security_token [^ ]*' | awk '{print $2}')

DATADOG_API_KEY=$(vault read -field=api_key secret/datadog/deploy)

dump_var "VAULT_ADDR"
dump_var "VAULT_TOKEN"
dump_var "AWS_ACCESS_KEY_ID"
dump_var "AWS_SECRET_ACCESS_KEY"
dump_var "AWS_SESSION_TOKEN"
dump_var "DATADOG_API_KEY"
