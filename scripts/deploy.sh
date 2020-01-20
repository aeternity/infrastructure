#!/usr/bin/env bash

set -eo pipefail

# back to the root dir
ROOT_DIR=$(dirname $(dirname $(readlink -fn $0)))
cd $ROOT_DIR
pwd

export DEPLOY_DB_VERSION=1
export PACKAGE=https://releases.aeternity.io/aeternity-${DEPLOY_VERSION:?}-ubuntu-x86_64.tar.gz

read -n 1 -p "Deploy blue UAT nodes? (y/N):" blueuatchoice
if [[ $blueuatchoice == "y" ]]; then
    DEPLOY_ENV=uat DEPLOY_COLOR=blue DEPLOY_DOWNTIME=600 make deploy
fi

read -n 1 -p "Deploy green UAT nodes? (y/N):" greenuatchoice
if [[ $greenuatchoice == "y" ]]; then
    DEPLOY_ENV=uat DEPLOY_COLOR=green DEPLOY_DOWNTIME=600 make deploy
fi

read -n 1 -p "Deploy MAIN nodes? (y/N):" mainchoice
if [[ $mainchoice == "y" ]]; then
    DEPLOY_ENV=main DEPLOY_DOWNTIME=600 ROLLING_UPDATE=30% make deploy
fi

read -n 1 -p "Deploy UAT monitoring nodes? (y/N):" uatmonchoice
if [[ $uatmonchoice == "y" ]]; then
    DEPLOY_ENV=uat_mon DEPLOY_REGION=ap-southeast-1 CONFIG_ENV=uat_mon@ap-southeast-1 make deploy
    DEPLOY_ENV=uat_mon DEPLOY_REGION=eu-central-1 CONFIG_ENV=uat_mon@eu-central-1 make deploy
    DEPLOY_ENV=uat_mon DEPLOY_REGION=eu-north-1 CONFIG_ENV=uat_mon@eu-north-1 make deploy
    DEPLOY_ENV=uat_mon DEPLOY_REGION=us-west-2 CONFIG_ENV=uat_mon@us-west-2 make deploy
fi

read -n 1 -p "Deploy MAIN monitoring nodes? (y/N):" mainmonchoice
if [[ $mainmonchoice == "y" ]]; then
    DEPLOY_ENV=main_mon DEPLOY_REGION=ap-southeast-1 CONFIG_ENV=main_mon@ap-southeast-1 make deploy
    DEPLOY_ENV=main_mon DEPLOY_REGION=eu-north-1 CONFIG_ENV=main_mon@eu-north-1 make deploy
    DEPLOY_ENV=main_mon DEPLOY_REGION=us-west-2 CONFIG_ENV=main_mon@us-west-2 make deploy
    DEPLOY_ENV=main_mon DEPLOY_REGION=us-east-2 CONFIG_ENV=main_mon@us-east-2 make deploy
fi

read -n 1 -p "Deploy UAT backup nodes? (y/N):" backupuatchoice
if [[ $backupuatchoice == "y" ]]; then
    DEPLOY_ENV=uat DEPLOY_KIND=backup make deploy
fi

read -n 1 -p "Deploy MAIN backup nodes? (y/N):" backupmainchoice
if [[ $backupmainchoice == "y" ]]; then
    DEPLOY_ENV=main DEPLOY_KIND=backup make deploy
fi

# restore the working dir
cd -

printf "\nDone!\n"
