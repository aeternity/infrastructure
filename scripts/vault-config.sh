#!/usr/bin/env bash

set -eo pipefail

CONFIG_OUTPUT_DIR=${CONFIG_OUTPUT_DIR:-/tmp/config}
CONFIG_ROOT=${CONFIG_ROOT:-secret2/aenode/config}
CONFIG_FIELD=${CONFIG_FIELD:-ansible_vars}
DEFAULT_FIELD_FILE_SUFFIX=${DEFAULT_FIELD_FILE_SUFFIX:-".yml"}
DRY_RUN=${DRY_RUN:-""}
KV2=${KV2:-"1"}

if [ $DRY_RUN ]; then
    echo "### RUNNING IN DRY RUN MODE ###"
    echo "# Write oprations will not be executed #"
    echo "----------------------------------------"
fi

usage() {
    USAGE="Usage:
    ${0} dump <config_keys>
    ${0} dmp-yml -f <file> -p <path> <config_keys>
    ${0} dump-all
    ${0} update <config_keys>
    ${0} update-yml -f <file> -p <path> -v <value> <config_keys>
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
        if [ $KV2 ]; then
            vault kv get -field=${config_field} ${CONFIG_ROOT:?}/${config_key} > ${CONFIG_FILE_PATH}
        else
            vault read -field=${config_field} ${CONFIG_ROOT:?}/${config_key} > ${CONFIG_FILE_PATH}
        fi
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

    if [ $KV2 ]; then
        local res=$(vault kv get -format=json ${config_path} | jq -r '.data.data | keys[]')
    else
        local res=$(vault read -format=json ${config_path} | jq -r '.data | keys[]')
    fi

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

dump_yml_value() {
    local config_path=${1:?}

    yq r "${config_path}/${YAML_FILE:?}" "${YAML_PATH:?}"
}

dump_yml() {
    local config_keys
    read -r -a config_keys <<< "${1:?}"

    for config_key in "${config_keys[@]}"
    do
        echo "### ${CONFIG_OUTPUT_DIR}/${config_key} ###"
        dump_yml_value "${CONFIG_OUTPUT_DIR}/${config_key}"
    done
}

dump_all() {
    if [ $KV2 ]; then
        local res=$(vault kv list ${CONFIG_ROOT:?} | tail -n +3)
    else
        local res=$(vault list ${CONFIG_ROOT:?} | tail -n +3)
    fi

    local config_keys
    mapfile -t config_keys <<< "${res}"

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

update_yml_value() {
    local config_path=${1:?}

    yq r "${config_path}/${YAML_FILE:?}" "${YAML_PATH:?}" "${YAML_VALUE:?}"
    yq w -i "${config_path}/${YAML_FILE:?}" "${YAML_PATH:?}" "${YAML_VALUE:?}"
}

update_yml() {
    local config_keys
    read -r -a config_keys <<< "${1:?}"

    for config_key in "${config_keys[@]}"
    do
        update_yml_value "${CONFIG_OUTPUT_DIR}/${config_key}"
        # update_config "${config_key}"
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
        dump-yml)
            shift
            while getopts "f:p:" option; do
               case $option in
                  f)
                    YAML_FILE=$OPTARG
                    ;;
                  p)
                    YAML_PATH=$OPTARG
                    ;;
                 \?) # not option
                    usage
                    ;;
               esac
            done
            shift $(($OPTIND - 1))
            dump_yml "$*"
            ;;
        dump-all)
            dump_all
            ;;
        update)
            update "${*:2}"
            ;;
        update-yml)
            shift
            while getopts "f:p:v:" option; do
               case $option in
                  f)
                    YAML_FILE=$OPTARG
                    ;;
                  p)
                    YAML_PATH=$OPTARG
                    ;;
                  v)
                    YAML_VALUE=$OPTARG
                    ;;
                 \?) # not option
                    usage
                    ;;
               esac
            done
            shift $(($OPTIND - 1))
            update_yml "$*"
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
