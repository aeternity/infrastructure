#!/usr/bin/env bash

set -eo pipefail

# back to the root dir
ROOT_DIR=$(dirname $(dirname $(readlink -fn $0)))
cd $ROOT_DIR
pwd

export DEPLOY_DB_VERSION=1
export PACKAGE=https://releases.aeternity.io/aeternity-${DEPLOY_VERSION:-}-ubuntu-x86_64.tar.gz

read -p "Deploy blue UAT nodes? (y/N):" blueuatchoice
if [[ $blueuatchoice == "y" ]]; then
    make vault-config-update-uat
    DEPLOY_ENV=uat DEPLOY_COLOR=blue DEPLOY_DOWNTIME=600 make deploy
fi

read -p "Deploy green UAT nodes? (y/N):" greenuatchoice
if [[ $greenuatchoice == "y" ]]; then
    make vault-config-update-uat
    DEPLOY_ENV=uat DEPLOY_COLOR=green DEPLOY_DOWNTIME=600 make deploy
fi

read -p "Deploy MAIN nodes? (y/N):" mainchoice
if [[ $mainchoice == "y" ]]; then
    make vault-config-update-main
    DEPLOY_ENV=main DEPLOY_DOWNTIME=600 ROLLING_UPDATE=30% make deploy
fi

# Monitoring nodes
read -p "Deploy UAT monitoring nodes? (y/N):" uatmonchoice
if [[ $uatmonchoice == "y" ]]; then
    make vault-config-update-uat_mon@ap-southeast-1
    make vault-config-update-uat_mon@eu-central-1
    make vault-config-update-uat_mon@eu-north-1
    make vault-config-update-uat_mon@us-west-2

    DEPLOY_ENV=uat_mon DEPLOY_REGION=ap-southeast-1 CONFIG_ENV=uat_mon@ap-southeast-1 make deploy
    DEPLOY_ENV=uat_mon DEPLOY_REGION=eu-central-1 CONFIG_ENV=uat_mon@eu-central-1 make deploy
    DEPLOY_ENV=uat_mon DEPLOY_REGION=eu-north-1 CONFIG_ENV=uat_mon@eu-north-1 make deploy
    DEPLOY_ENV=uat_mon DEPLOY_REGION=us-west-2 CONFIG_ENV=uat_mon@us-west-2 make deploy
fi

read -p "Deploy MAIN monitoring nodes? (y/N):" mainmonchoice
if [[ $mainmonchoice == "y" ]]; then
    make vault-config-update-main_mon@ap-southeast-1
    make vault-config-update-main_mon@eu-north-1
    make vault-config-update-main_mon@us-west-2
    make vault-config-update-main_mon@us-east-2

    DEPLOY_ENV=main_mon DEPLOY_REGION=ap-southeast-1 CONFIG_ENV=main_mon@ap-southeast-1 make deploy
    DEPLOY_ENV=main_mon DEPLOY_REGION=eu-north-1 CONFIG_ENV=main_mon@eu-north-1 make deploy
    DEPLOY_ENV=main_mon DEPLOY_REGION=us-west-2 CONFIG_ENV=main_mon@us-west-2 make deploy
    DEPLOY_ENV=main_mon DEPLOY_REGION=us-east-2 CONFIG_ENV=main_mon@us-east-2 make deploy
fi

# Backup nodes
read -p "Deploy UAT backup nodes? (y/N):" backupuatchoice
if [[ $backupuatchoice == "y" ]]; then
    make vault-config-update-uat_backup
    DEPLOY_ENV=uat DEPLOY_KIND=backup CONFIG_ENV=uat_backup make deploy
fi

read -p "Deploy MAIN backup nodes? (y/N):" backupmainchoice
if [[ $backupmainchoice == "y" ]]; then
    make vault-config-update-main_backup
    DEPLOY_ENV=main DEPLOY_KIND=backup CONFIG_ENV=main_backup make deploy
fi

# Testnet gateway nodes
read -p "Deploy testnet API gateway - Stockholm? (y/N):" testnetgate1
if [[ $testnetgate1 == "y" ]]; then
    make vault-config-update-api_uat
    DEPLOY_ENV=api_uat DEPLOY_REGION=eu_north_1 make deploy
fi

read -p "Deploy testnet API gateway - Singapore? (y/N):" testnetgate2
if [[ $testnetgate2 == "y" ]]; then
    make vault-config-update-api_uat
    DEPLOY_ENV=api_uat DEPLOY_REGION=ap_southeast_1 make deploy
fi

# Mainnet gateway nodes
read -p "Deploy mainnet API gateway - Stockholm? (y/N):" mainnetgate1
if [[ $mainnetgate1 == "y" ]]; then
    make vault-config-update-api_main
    DEPLOY_ENV=api_main DEPLOY_REGION=eu_north_1 make deploy
fi

read -p "Deploy mainnet API gateway - Singapore? (y/N):" mainnetgate2
if [[ $mainnetgate2 == "y" ]]; then
    make vault-config-update-api_main
    DEPLOY_ENV=api_main DEPLOY_REGION=ap_southeast_1 make deploy
fi

read -p "Deploy mainnet API gateway - Oregon? (y/N):" mainnetgate3
if [[ $mainnetgate3 == "y" ]]; then
    make vault-config-update-api_main
    DEPLOY_ENV=api_main DEPLOY_REGION=us-west-2 make deploy
fi

# restore the working dir
cd -

printf "\nDone!\n"
