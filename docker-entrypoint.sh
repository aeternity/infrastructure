#!/bin/bash
set -e

source import-secrets.sh

exec "$@"
