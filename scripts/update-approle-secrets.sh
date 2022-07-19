#!/usr/bin/env bash

set -eo pipefail

function update_circleci_var()
{
    local CONTEXT=$1
    local VAR=$2
    local VAL=$3

    curl --request PUT \
      --url https://circleci.com/api/v2/context/$CONTEXT/environment-variable/$VAR \
      --header "Circle-Token: $CIRCLECI_TOKEN" \
      --header 'content-type: application/json' \
      --data "{\"value\":\"$VAL\"}"
}

function update_circleci()
{
    ROLE_ID=$(vault read -field=role_id auth/approle/role/$1/role-id)
    SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/$1/secret-id)
    update_circleci_var $2 VAULT_ROLE_ID $ROLE_ID
    update_circleci_var $2 VAULT_SECRET_ID $SECRET_ID
}

# Update CircleCI
export CIRCLECI_TOKEN=$(vault read -field=token secret/circleci)
update_circleci node-ci 7af9c87e-bb81-4a5c-914f-592af402de40
update_circleci infra-ci a68d10ca-beed-4b84-bf91-288aa2357000
update_circleci node-images-ci d0451cab-58f4-4875-81cf-bec45d0d4ac3
update_circleci apt-ci ca11d697-f5bd-45ef-9c38-b3386804509a

# Update SSM
SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/batch-jobs/secret-id)
aws ssm put-parameter --region eu-west-2 --type SecureString --overwrite --name vault_batch_secret_id --value $SECRET_ID
