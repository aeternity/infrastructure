#!/usr/bin/env bash

set -eo pipefail

CONFIG_OUTPUT_DIR=${CONFIG_OUTPUT_DIR:-/tmp/config}
CONFIG_ROOT=${CONFIG_ROOT:-secret2/aenode/config}
CONFIG_FIELD=${CONFIG_FIELD:-ansible_vars}
DEFAULT_FIELD_FILE_SUFFIX=${DEFAULT_FIELD_FILE_SUFFIX:-".yml"}
DRY_RUN=${DRY_RUN:-""}
KV2=${KV2:-""}

if [ $DRY_RUN ]; then
    echo "### RUNNING IN DRY RUN MODE ###"
    echo "# Write oprations will not be executed #"
    echo "----------------------------------------"
fi

usage() {
    USAGE="Usage:
    ${0} dump <config_key>
    ${0} dump-all
    ${0} update <config_key>
    ${0} update-all
    "

    echo -e "$USAGE" >&2; exit 1
}

# "return value"
CONFIG_FILE_PATH=""
set_config_file_path() {
    local config_key=${1:?}
    local config_field=${2:?}
    local field_file_suffix=${DEFAULT_FIELD_FILE_SUFFIX}

    if [[ "$config_field" == *yml || "$config_field" == *yaml ]]; then
        field_file_suffix=".yml"
    elif [[ "$config_field" == *json ]]; then
        field_file_suffix=".json"
    fi

    CONFIG_FILE_PATH="${CONFIG_OUTPUT_DIR}/${config_key}/${config_field}${field_file_suffix}"
}

dump_field() {
    local config_key=${1:?}
    local config_field=${2:?}

    set_config_file_path $config_key $config_field
    echo "Dumping field: $CONFIG_FILE_PATH"

    if [ $DRY_RUN ]; then
        vault read -field=${config_field} ${CONFIG_ROOT:?}/${config_key} > /dev/null
    else
        mkdir -p ${CONFIG_OUTPUT_DIR}/${config_key}
        vault read -field=${config_field} ${CONFIG_ROOT:?}/${config_key} > ${CONFIG_FILE_PATH}
    fi
}

update_field() {
    local config_key=${1:?}
    local config_field=${2:?}

    set_config_file_path $config_key $config_field
    echo "Updating field: $CONFIG_FILE_PATH"

    if [ ! $DRY_RUN ]; then
        if [ $KV2 ]; then
            cat ${CONFIG_FILE_PATH} | vault kv patch ${CONFIG_ROOT:?}/${config_key} ${config_field}=-
        else
            cat ${CONFIG_FILE_PATH} | vault write ${CONFIG_ROOT:?}/${config_key} ${config_field}=-
        fi
    fi
}

# Dump all config fields
dump_config() {
    local config_key=${1:?}
    local config_path=${CONFIG_ROOT:?}/${config_key}

    echo "Dumping config: $config_path"

    local res=$(vault read -format=json ${config_path} | jq -r '.data | keys[]')
    mapfile -t fields <<< "$res"

    for field in "${fields[@]}"
    do
       dump_field "${config_key}" "$field"
    done
}

# Update all config fields from a directory
update_config() {
    local config_key=${1:?}
    local config_path=${CONFIG_ROOT:?}/${config_key}

    echo "Updating config: $config_path"

    if [ $KV2 ]; then
        if [ ! $DRY_RUN ]; then
            vault kv delete ${config_path}
            vault kv put ${config_path} ansible_vars=""
        fi
    fi

    local res=$(ls "${CONFIG_OUTPUT_DIR}/${config_key}")
    mapfile -t field_files <<< "$res"

    for file_path in "${field_files[@]}"
    do
       update_field "${config_key}" "${file_path%.*}"
    done
}

dump() {
    local config_keys
    read -r -a config_keys <<< "${1:?}"

    for config_key in "${config_keys[@]}"
    do
       dump_config "${config_key}"
    done
}

update() {
    local config_keys
    read -r -a config_keys <<< "${1:?}"

    for config_key in "${config_keys[@]}"
    do
       update_config "${config_key}"
    done
}

dump_all() {
    local res=$(vault list ${CONFIG_ROOT:?} | tail -n +3)
    local config_keys
    mapfile -t config_keys <<< "${res}"

    for config_key in "${config_keys[@]}"
    do
       dump_config "${config_key}"
    done
}

update_all() {
    local res=$(ls "${CONFIG_OUTPUT_DIR}")
    mapfile -t config_keys <<< "$res"

    local config_key
    for config_key in "${config_keys[@]}"
    do
       update_config "${config_key}"
    done    
}

### MAIN ###
if [[ -n "$1" ]]; then
    case "$1" in
        dump)
            dump "${*:2}"
            ;;
        dump-all)
            dump_all
            ;;
        update)
            update "${*:2}"
            ;;
        update-all)
            update_all
            ;;
        *)
            usage
            ;;
    esac
else
    usage
fi
