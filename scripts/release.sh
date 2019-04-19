#!/bin/bash
# should be run as:
# ./release.sh x.x.x start|finish description
set -eo pipefail

USAGE="Usage:
${0} x.x.x start|finish description, E.g. to start a release run:
${0} 2.4.0 start Maintenance release
then to finish the release run:
${0} 2.4.0 finish"

protocol_repo=valerifilipov/repo2
node_repo=valerifilipov/repo1

#generate_post_data release description
generate_post_data() {
cat <<EOF
{
  "tag_name": "$1",
  "target_commitish": "master",
  "name": "$2",
  "body": "$1",
  "draft": false,
  "prerelease": $prerelease
}
EOF
}

curl_headers=(
    '-H' "Accept: application/vnd.github.v3+json"
    '-H' "Authorization: token $VAULT_GITHUB_TOKEN"
    '-H' "Content-Type: application/json"
    '-H' "cache-control: no-cache"
)

#create_release repo release description
create_release() {
    postdata=$(generate_post_data "$2" "$3")
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
        -d '{"prerelease":'$prerelease'}'
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
        echo Release $protocol_release not found >&2; exit 1
    fi
}

#check for release version
if [[ -n "$1" && "$1" =~ ^([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)*)$ ]]; then
    version=${1}
    shift
else
    echo -e "$USAGE" >&2; exit 1
fi

protocol_release=aeternity-node-v$version
node_release=v$version

echo protocol release: $protocol_release
echo node release: $node_release

#check for action
if [[ -n "$1" ]]; then
    if [[ "$1" == start ]]; then
        prerelease=true
        shift
    else
        if [[ "$1" == finish ]]; then
            prerelease=false
        else
            echo -e "$USAGE" >&2; exit 1
        fi
    fi
else
    echo -e "$USAGE" >&2; exit 1
fi

#check for description
if [[ $# -gt 0 ]]; then
    desription="$@"
else
    echo -e "$USAGE" >&2; exit 1
fi

if [[ $prerelease == true ]]; then
    echo "Creating pre-release $protocol_release in $protocol_repo"
    create_release $protocol_repo $protocol_release "$desription"
    echo "Creating pre-release $node_release in $node_repo"
    create_release $node_repo $node_release "$desription"
else
    echo "Creating release $protocol_release for repo: $protocol_repo"
    finish_release $protocol_repo $protocol_release
    echo "Creating release $node_release for repo: $node_repo"
    finish_release $node_repo $node_release
fi
