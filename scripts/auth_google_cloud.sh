#!/bin/bash
# Do not run after first error
set -eo pipefail

for i in "$@"
do
case $i in
    --vault_addr=*)
    vault_addr="${i#*=}"
    shift # past argument=value
    ;;
    --vault_role=*)
    vault_role="${i#*=}"
    shift # past argument=value
    ;;
    --env=*)
    env="${i#*=}"
    shift # past argument=value
    ;;
    --epoch_package=*)
    epoch_package="${i#*=}"
    shift # past argument=value
    ;;
    --platform=*)
    platform="${i#*=}"
    shift # past argument=value
    ;;

    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done


INSTANCE_AUTH_TOKEN=$(-H "Metadata-Flavor: Google" 'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?audience=epoch&format=full' | tr -d '\n')

echo "test"
