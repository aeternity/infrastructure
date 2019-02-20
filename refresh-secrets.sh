#!/bin/bash

vault token revoke -self
unset VAULT_TOKEN
source import-secrets.sh
