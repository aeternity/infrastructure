#!/bin/bash
#example usage: health_check.sh --network=main --min_height=52000 --version=2.1.0 18.136.37.63
set -eo pipefail

declare -A network_genesis_hashmap
network_genesis_hashmap['main']="kh_pbtwgLrNu23k9PA6XCZnUbtsvEFeQGgavY4FS2do3QP8kcp2z"
network_genesis_hashmap['uat']="kh_wUCideEB8aDtUaiHCtKcfywU6oHZW6gnyci8Mw6S1RSTCnCRu"
declare -A network_id_hashmap
network_id_hashmap['main']=ae_mainnet
network_id_hashmap['uat']=ae_uat

for arg in "$@"; do
    case $arg in
        --network=*)
        network="${arg#*=}"
        network_id=${network_id_hashmap[$network]}
        genesis_hash=${network_genesis_hashmap[$network]}
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

min_height=${min_height:-1}

get_node_status() {
    curl -sS -m5 http://$HOST:3013/v2/status
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
    test $(curl -sS -m5 http://$HOST:3013/v2/key-blocks/current | jq '.height') -ge $min_height
}
check_version() {
    test $(echo $node_status| jq -r '.node_version') == $version
}

node_status=$(get_node_status)
check_top_min_height || failed+=" min_height"

if [ -n "$genesis_hash" ]; then
    check_genesis_hash || failed+=" genesis"
fi
if [ -n "$network_id" ]; then
    check_network_id || failed+=" network_id"
fi
if [ -n "$version" ]; then
    check_version || failed+=" version"
fi
if [ -n "$min_sync_pct" ]; then
    if [ "$(check_sync_progress)" -ne 1 ]; then
       failed+=" sync_progress"
    fi
fi

if [ "$failed" != "" ]; then
    for fail in $failed; do
        echo "$fail" check failed
    done
    exit 1
fi
