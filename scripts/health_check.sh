#!/usr/bin/env bash
#example usage: health_check.sh --network=main --min_height=55000 --version=2.1.0 $HOSTNAME
#--genesis_hash & --network_id override defaults for --network
set -eo pipefail

genesis_hash_main="kh_pbtwgLrNu23k9PA6XCZnUbtsvEFeQGgavY4FS2do3QP8kcp2z"
genesis_hash_uat="kh_wUCideEB8aDtUaiHCtKcfywU6oHZW6gnyci8Mw6S1RSTCnCRu"
network_id_main=ae_mainnet
network_id_uat=ae_uat

for arg in "$@"; do
    case $arg in
        --network=*)
        network="${arg#*=}"
        genesis_hash_var=genesis_hash_${network}
        genesis_hash=${!genesis_hash_var}
        network_id_var=network_id_${network}
        network_id=${!network_id_var}
        shift # past argument=value
        ;;
        --network_id=*)
        network_id="${arg#*=}"
        shift
        ;;
        --min_height=*)
        min_height="${arg#*=}"
        shift
        ;;
        --genesis_hash=*)
        genesis_hash="${arg#*=}"
        shift
        ;;
        --min_sync_pct=*)
        min_sync_pct="${arg#*=}"
        shift
        ;;
        --version=*)
        version="${arg#*=}"
        shift
        ;;
        *)
              # unknown option
        ;;
    esac
done

if [ $# -eq 0 ]; then
    HOST=127.0.0.1
else
    HOST=${@:$#}
fi

min_height=${min_height:-0}

get_node_status() {
    curl -sS -m5 http://$HOST:3013/v3/status
}
check_genesis_hash() {
    test $(echo $node_status| jq -r '.genesis_key_block_hash') == $genesis_hash
}
check_network_id() {
    test $(echo $node_status| jq -r '.network_id') == $network_id
}
check_sync_progress() {
    echo "$(echo $node_status| jq -r '.sync_progress')>=$min_sync_pct"|bc
}
check_top_min_height() {
    test $(curl -sS -m5 http://$HOST:3013/v3/key-blocks/current | jq '.height') -ge $min_height
}
check_version() {
    test $(echo $node_status| jq -r '.node_version') == $version
}

node_status=$(get_node_status)
passed=node_status

check_top_min_height && passed+=" min_height"|| failed+=" min_height"

if [ -n "$genesis_hash" ]; then
    check_genesis_hash && passed+=" genesis"|| failed+=" genesis"
fi
if [ -n "$network_id" ]; then
    check_network_id  && passed+=" network_id"|| failed+=" network_id"
fi
if [ -n "$version" ]; then
    check_version && passed+=" version"|| failed+=" version"
fi
if [ -n "$min_sync_pct" ]; then
    if [ "$(check_sync_progress)" -ne 1 ]; then
        failed+=" sync_progress"
    else
        passed+=" sync_progress"
    fi
fi

if [ "$passed" != "" ]; then
    printf "Passed tests:\n"
    for pass in $passed; do
        printf "%s\n" "- $pass"
    done
fi
if [ "$failed" != "" ]; then
    printf "\nFailed tests:\n" >&2
    for fail in $failed; do
        printf "%s\n" "- $fail" >&2
    done
    exit 1
fi
