#!/bin/bash
#example usage: test/scripts/health_check.sh --network=main --height=52000 --version=2.1.0 18.136.37.63
set -eo pipefail

main_network_id=ae_mainnet
uat_network_id=ae_uat
main_genesis="kh_pbtwgLrNu23k9PA6XCZnUbtsvEFeQGgavY4FS2do3QP8kcp2z"
uat_genesis="kh_wUCideEB8aDtUaiHCtKcfywU6oHZW6gnyci8Mw6S1RSTCnCRu"
node_version=2.1.0

for arg in "$@"; do
    case $arg in
        --network=*)
        network="${arg#*=}"
        shift # past argument=value
        ;;
        --height=*)
        height="${arg#*=}"
        shift # past argument=value
        ;;
        --version=*)
        version="${arg#*=}"
        shift # past argument=value
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

network=${network:-main}
height=${height:-0}
version=${version:-$node_version}
network_id=${network}_network_id
network_genesis=${network}_genesis

get_node_status() {
    curl -sS -m5 http://$HOST:3013/v2/status
}
check_genesis_hash() {
    test $(echo $node_status| jq -r '.genesis_key_block_hash') == ${!network_genesis}
}
check_network_id() {
    test $(echo $node_status| jq -r '.network_id') ==  ${!network_id}
}
check_top_height() {
    test $(curl -sS -m5 http://$HOST:3013/v2/key-blocks/current | jq '.height') -gt $height
}
check_version() {
    test $(echo $node_status| jq -r '.node_version') == $version
}

node_status=$(get_node_status)

check_genesis_hash || (echo "genesis check failed"; exit 1)
check_top_height || (echo "height check failed"; exit 1)
check_network_id || (echo "network check failed"; exit 1)
check_version || (echo "version check failed"; exit 1)
