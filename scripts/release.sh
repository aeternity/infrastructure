#!/usr/bin/env bash
# should be run as:
# ./release.sh x.x.x start|finish description [--protocol-commitish=master] [--node-commitish=master]
set -eo pipefail

USAGE="Usage:
${0} x.x.x start|finish description [--protocol-commitish=master] [--node-commitish=master], e.g. to start a release run:
${0} v2.4.0 start Maintenance release
then to finish the release run:
${0} v2.4.0 finish"

protocol_repo=${PROTOCOL_REPO:-aeternity/protocol}
node_repo=${NODE_REPO:-aeternity/aeternity}
protocol_commitish=master
node_commitish=master
github_token=${AE_GITHUB_TOKEN:-${AE_VAULT_GITHUB_TOKEN:?}}

usage_exit() {
    echo -e "$USAGE" >&2; exit 1
}

#generate_post_data release commitish description
generate_post_data() {
BODY=${4:-${3:?}}

cat <<EOF
{
  "tag_name": "$1",
  "target_commitish": "${2}",
  "name": "$3",
  "body": "$BODY",
  "draft": false,
  "prerelease": true
}
EOF
}

curl_headers=(
    '-H' "Accept: application/vnd.github.v3+json"
    '-H' "Authorization: token ${github_token}"
    '-H' "Content-Type: application/json"
    '-H' "cache-control: no-cache"
)

#create_release repo release commitish description
create_release() {
    postdata=$(generate_post_data "$2" "$3" "$4" "$5")
    released=$(curl -s -X POST \
        "${curl_headers[@]}" \
        https://api.github.com/repos/${1}/releases \
        -d "$postdata")
    if [[ $(echo $released| jq -r '.id') != null ]]; then
        echo Pre-release created
    else
        echo $released| jq -r '.errors' >&2; exit 1
    fi
}

#get_release_by_tag repo tag
get_release_by_tag() {
    curl -s "${curl_headers[@]}" https://api.github.com/repos/$1/releases/tags/$2| jq -r '.id'
}

edit_release() {
    curl -s -X PATCH \
        "${curl_headers[@]}" \
        https://api.github.com/repos/$1/releases/$2 \
        -d '{"prerelease":false}'
}

#finish_release repo release
finish_release() {
    release_id=$(get_release_by_tag "$1" "$2")
    if [[ "$release_id" != null ]]; then
        released=$(edit_release $1 $release_id)
        if [[ $(echo "$released"|jq -r '.id') == "$release_id" ]]; then
            echo "$2" released sucessfully in "$1"
        else
            echo "Could not release $2 in $1. Error was:\n" >&2
            echo $released|jq -r '.errors' >&2
            exit 1
        fi
    else
        echo Release "$2" not found >&2; exit 1
    fi
}

#check for release version
if [[ -n "$1" && "$1" =~ ^v([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9\.\+]+)*)$ ]]; then
    protocol_release=aeternity-node-${1}
    node_release=${1}
    shift
else
    usage_exit
fi


#check for action and subject then create release
if [[ -n "$1" ]]; then
    case "$1" in
        start)
            prerelease=true
            shift
            for arg in "$@"; do
                case $arg in
                    --protocol-commitish=*)
                        protocol_commitish="${arg#*=}"
                        shift
                        ;;
                    --node-commitish=*)
                        node_commitish="${arg#*=}"
                        shift
                        ;;
                    *)
                        subject+=(${arg})
                        ;;
                esac
            done
            if [[ -z "$subject" ]]; then
                usage_exit
            fi
            subject=${subject[@]}
            echo "Creating pre-release ${protocol_release:?} $subject in $protocol_repo from commitish $protocol_commitish"
            create_release $protocol_repo ${protocol_release:?} $protocol_commitish "$subject"
            echo "Creating pre-release ${node_release:?} $subject in $node_repo from commitish $node_commitish"
            description="Please see the [release notes](https://github.com/$node_repo/blob/$node_release/docs/release-notes/RELEASE-NOTES-${node_release:1}.md)."
            create_release $node_repo ${node_release:?} $node_commitish "$subject" "$description"
            ;;
        finish)
            prerelease=false
            shift
            echo "Publishing release ${protocol_release:?} for repo: $protocol_repo"
            finish_release $protocol_repo ${protocol_release:?}
            echo "Publishing release ${node_release:?} for repo: $node_repo"
            finish_release $node_repo ${node_release:?}
            ;;
        *)
            usage_exit
            ;;
    esac
else
    usage_exit
fi
