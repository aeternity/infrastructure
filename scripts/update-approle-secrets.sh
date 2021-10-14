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
update_circleci node-ci 81741cd0-d6ba-4380-8c8a-49c625fc7ca2
update_circleci infra-ci 167aeaef-d241-4b47-8bb5-86f4fa785101
update_circleci node-images-ci a3ab7a2d-75ff-44f9-8c9f-016e66850ed8
update_circleci apt-ci 96ec8d55-4a50-4f0a-8337-b0a7e0443a62

# Update SSM
SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/batch-jobs/secret-id)
aws ssm put-parameter --region eu-west-2 --type SecureString --overwrite --name vault_batch_secret_id --value $SECRET_ID
