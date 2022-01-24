#!/usr/bin/env bash
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

declare -a targets=(ubuntu-x86_64.tar.gz macos-x86_64.tar.gz)
declare -a prefixes=(aeternity aeternity-bundle)
repo_name=aeternity/aeternity

check_release_asset() {
    curl -fsS -o /dev/null --head "$1" 2>&1
}

check_github_release_assets() {
    for target in "${targets[@]}"; do
        for prefix in "${prefixes[@]}"; do
            GH_ASSET=https://github.com/$repo_name/releases/download/$release/$prefix-v$version-$target
            if [[ $(check_release_asset $GH_ASSET) != "" ]]; then
                echo $GH_ASSET check failed >&2; failed=true
            fi
            # TODO: compare MD5 checksum with local build
        done
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
        local version_package=https://releases.aeternity.io/aeternity-v$version-$target
        local bundle_package=https://releases.aeternity.io/aeternity-bundle-v$version-$target
        local latest_package=https://releases.aeternity.io/aeternity-latest-$target
        # TODO: calculate ETAG from local package MD5 sum and verify
        # https://teppen.io/2018/10/23/aws_s3_verify_etags/
        local version_etag=$(get_s3_package_etag $version_package)
        local bundle_etag=$(get_s3_package_etag $bundle_package)
        local latest_etag=$(get_s3_package_etag $latest_package)

        if [[ "$version_etag" == "" ]]; then
            echo $version_package not found >&2; failed=true
        else
            if [[ "$version_etag" != "$latest_etag" ]]; then
                echo $latest_package and $version_package checksums do not match >&2; failed=true
            fi
        fi

        if [[ "$bundle_etag" == "" ]]; then
            echo $bundle_package not found >&2; failed=true
        fi
    done
}

check_github_release_assets
check_dockerhub_assets
check_s3_artifacts

if [ "$failed" = true ]; then
    exit 1
fi
