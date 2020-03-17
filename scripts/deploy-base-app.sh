#!/usr/bin/env bash

set -eo pipefail

VERSION="${1:?You must pass a version of the format x.y.z as the only argument}"
S3_BUCKET=${S3_BUCKET:-s3://aeternity-aepp-base}
CF_DISTRIBUTION_ID=${CF_DISTRIBUTION_ID:-EQFJCAMGJPD4C}
PACKAGE_URL=https://github.com/aeternity/aepp-base/releases/download/v${VERSION:?}/aeternity.tar.gz
PACKAGE_TMP_DIR=${PACKAGE_TMP_DIR:-/tmp/aepp-base-${VERSION}}


mkdir -p ${PACKAGE_TMP_DIR}
curl -L -o ${PACKAGE_TMP_DIR}/aeternity.tar.gz ${PACKAGE_URL}
tar -xzf ${PACKAGE_TMP_DIR}/aeternity.tar.gz -C ${PACKAGE_TMP_DIR}

aws s3 sync --acl public-read ${PACKAGE_TMP_DIR}/dist ${S3_BUCKET}
aws cloudfront create-invalidation --distribution-id ${CF_DISTRIBUTION_ID} --paths '/*'

printf "\nDone! Cache invalidation may take a while.\n"
