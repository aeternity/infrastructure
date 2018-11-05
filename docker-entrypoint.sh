#!/bin/bash
set -e

source /infrastructure/import-secrets.sh

exec "$@"
