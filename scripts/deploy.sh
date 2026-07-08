#!/usr/bin/env bash

set -eo pipefail

# back to the root dir
ROOT_DIR=$(dirname $(dirname $(readlink -fn $0)))
cd $ROOT_DIR
pwd

export DEPLOY_DB_VERSION=1
export PACKAGE=https://releases.aeternity.io/aeternity-${DEPLOY_VERSION:?}-ubuntu-x86_64.tar.gz

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
    make vault-config-update-uat_mon@eu-central-1

    DEPLOY_ENV=uat_mon DEPLOY_REGION=eu-north-1 CONFIG_KEY=uat_mon@eu-central-1 make deploy
fi

read -p "Deploy MAIN monitoring nodes? (y/N):" mainmonchoice
if [[ $mainmonchoice == "y" ]]; then
    make vault-config-update-main_mon@eu-north-1

    DEPLOY_ENV=main_mon DEPLOY_REGION=eu-north-1 CONFIG_KEY=main_mon@eu-north-1 make deploy
fi

# Backup nodes
# NOTE: uat_backup / main_backup nodes are currently decommissioned
# (see "Remove backup and spot nodes" in terraform-aws-testnet and the
# commented-out main_backup modules in terraform-aws-mainnet). Re-enable
# below once/if the backup fleet is provisioned again.
# read -p "Deploy UAT backup nodes? (y/N):" backupuatchoice
# if [[ $backupuatchoice == "y" ]]; then
#     make vault-config-update-uat_backup_light
#     make vault-config-update-uat_backup_full
#     DEPLOY_ENV=uat_backup DEPLOY_KIND=light CONFIG_KEY=uat_backup_light make deploy
#     DEPLOY_ENV=uat_backup DEPLOY_KIND=full CONFIG_KEY=uat_backup_full make deploy
# fi
#
# read -p "Deploy MAIN backup nodes? (y/N):" backupmainchoice
# if [[ $backupmainchoice == "y" ]]; then
#     make vault-config-update-main_backup_light
#     make vault-config-update-main_backup_full
#     DEPLOY_ENV=main_backup DEPLOY_KIND=light CONFIG_KEY=main_backup_light make deploy
#     DEPLOY_ENV=main_backup DEPLOY_KIND=full CONFIG_KEY=main_backup_full make deploy
# fi

# Testnet gateway nodes
# NOTE: gateway nodes are static nodes tagged kind=seed by the
# terraform-aws-aenode-deploy module; kind=peer is only applied to the spot
# fleet, which is scaled to 0 for every API gateway env, so DEPLOY_KIND="peer"
# was replaced with DEPLOY_KIND="seed" here (it no longer matched any host).
# DEPLOY_KIND="seed" is required to avoid also matching any non-seed (e.g.
# kind=channel) hosts that may share the same env/role tags.
read -p "Deploy testnet API gateway - Stockholm? (y/N):" testnetgate1
if [[ $testnetgate1 == "y" ]]; then
    make vault-config-update-api_uat
    DEPLOY_ENV=api_uat DEPLOY_REGION=eu_north_1 DEPLOY_KIND="seed" make deploy
fi

# NOTE: testnet API gateway Singapore + Stockholm channel node are currently
# decommissioned (see "Remove Singapore and SC node" in terraform-aws-testnet-api).
# read -p "Deploy testnet API gateway - Singapore? (y/N):" testnetgate2
# if [[ $testnetgate2 == "y" ]]; then
#     make vault-config-update-api_uat
#     DEPLOY_ENV=api_uat DEPLOY_REGION=ap_southeast_1 DEPLOY_KIND="peer" make deploy
# fi

# Mainnet gateway nodes
read -p "Deploy mainnet API gateway - Stockholm? (y/N):" mainnetgate1
if [[ $mainnetgate1 == "y" ]]; then
    make vault-config-update-api_main
    DEPLOY_ENV=api_main DEPLOY_REGION=eu_north_1 DEPLOY_KIND="seed" make deploy

    make vault-config-update-api_main_channel
    DEPLOY_ENV=api_main DEPLOY_REGION=eu_north_1 DEPLOY_KIND="channel" CONFIG_KEY=api_main_channel make deploy
fi

# NOTE: mainnet API gateway Singapore and Oregon are currently decommissioned
# (see "Remove Oregon and Singapore" in terraform-aws-mainnet-api).
# read -p "Deploy mainnet API gateway - Singapore? (y/N):" mainnetgate2
# if [[ $mainnetgate2 == "y" ]]; then
#     make vault-config-update-api_main
#     DEPLOY_ENV=api_main DEPLOY_REGION=ap_southeast_1 DEPLOY_KIND="peer" make deploy
# fi
#
# read -p "Deploy mainnet API gateway - Oregon? (y/N):" mainnetgate3
# if [[ $mainnetgate3 == "y" ]]; then
#     make vault-config-update-api_main
#     DEPLOY_ENV=api_main DEPLOY_REGION=us-west-2 DEPLOY_KIND="peer" make deploy
# fi

# restore the working dir
cd -

printf "\nDone!\n"
