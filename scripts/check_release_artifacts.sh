#!/bin/bash
# should be run in CI or manually as:
# ./check_release_artifacts.sh v2.3.1
# DOCKER_USER and DOCKER_PASS need to be set for dockerhub checks when run manually
set -e

if [[ -n "$1" ]]; then
    release=${1}
else
    echo specify release version e.g. ${0} v2.3.0 >&2; exit 1
fi

failed=false
if [[ -n $release && $release =~ ^v([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)*)$ ]]; then
    version=${BASH_REMATCH[1]}
else
    version=$release
fi

declare -a targets=(ubuntu macos)
repo_name=aeternity/aeternity

check_release_asset() {
    curl -fsS -o /dev/null --head "$1" 2>&1
}

check_github_release_assets() {
    for target in "${targets[@]}"; do
        GH_ASSET=https://github.com/$repo_name/releases/download/$release/aeternity-$version-$target-x86_64.tar.gz
        if [[ $(check_release_asset $GH_ASSET) != "" ]]; then
            echo $GH_ASSET check failed >&2; failed=true
        fi
        # TODO: compare MD5 checksum with local build
    done
}

get_dockerhub_token() {
    curl --silent --user "${DOCKER_USER}:${DOCKER_PASS}" \
        "https://auth.docker.io/token?scope=repository:$repo_name:pull&service=registry.docker.io" \
        |jq -r .token
}

get_docker_image_digest() {
    local image=$1
    local tag=$2
    local token=$3
   curl \
    --silent \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    --header "Authorization: Bearer $token" \
    "https://index.docker.io/v2/$image/manifests/$tag" \
    | jq -r '.config.digest'
}

get_docker_image_config() {
  local image=$1
  local token=$2
  local digest=$3

  curl \
    --silent \
    --location \
    --header "Authorization: Bearer $token" \
    "https://registry-1.docker.io/v2/$image/blobs/$digest" \
    | jq -r '.container_config'
}

check_dockerhub_assets() {
    token=$(get_dockerhub_token)
    if [[ "$token" == "null" ]]; then
        echo could not authenticate to dockerhub >&2; failed=true
    else
        version_digest=$(get_docker_image_digest $repo_name $release $token)
        latest_digest=$(get_docker_image_digest $repo_name latest $token)
        if [[ "$version_digest" == "null" ]]; then
            echo docker image tag $release not found >&2; failed=true
        else
            if [[ "$version_digest" != "$latest_digest" ]]; then
                echo latest and $release docker image tag digests do not match >&2; failed=true
            fi
        fi
    # TODO: compare digest to local image build
    # get_docker_image_config $repo_name $token $digest
    fi

}

get_s3_package_etag(){
    curl --silent --head $1| grep etag|awk '{print $2}'|tr -d '"'
}

check_s3_artifacts() {
    for target in "${targets[@]}"; do
        local version_package=https://releases.ops.aeternity.com/aeternity-$version-$target-x86_64.tar.gz
        local latest_package=https://releases.ops.aeternity.com/aeternity-latest-$target-x86_64.tar.gz
        # TODO: calculate ETAG from local package MD5 sum and verify
        # https://teppen.io/2018/10/23/aws_s3_verify_etags/
        local latest_etag=$(get_s3_package_etag $latest_package)
        local version_etag=$(get_s3_package_etag $version_package)
        if [[ "$version_etag" == "" ]]; then
            echo $version_package not found >&2; failed=true
        else
            if [[ "$latest_etag" == "" ]]; then
                echo $latest_package not found >&2; failed=true
            else
                if [[ "$version_etag" != "$latest_etag" ]]; then
                    echo $latest_package and $version_package checksums do not match >&2; failed=true
                fi
            fi
        fi
    done
}

check_github_release_assets
check_dockerhub_assets
check_s3_artifacts

if [ "$failed" = true ]; then
    exit 1
fi
