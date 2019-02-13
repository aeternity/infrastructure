#!/bin/bash

vault token revoke -self
unset VAULT_TOKEN
source /infrastructure/import-secrets.sh
