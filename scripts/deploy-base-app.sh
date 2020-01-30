#!/usr/bin/env bash

set -eo pipefail

VERSION="${1:?You must pass a version of the format x.y.z as the only argument}"
S3_BUCKET=${S3_BUCKET:-s3://aeternity-aepp-base}
CF_DISTRIBUTION_ID=${CF_DISTRIBUTION_ID:-EQFJCAMGJPD4C}
PACKAGE_URL=https://github.com/aeternity/aepp-base/releases/download/v${VERSION:?}/aepp-base-${VERSION:?}.zip
PACKAGE_TMP_DIR=${PACKAGE_TMP_DIR:-/tmp}


curl -L -o ${PACKAGE_TMP_DIR}/aepp-base-${VERSION}.zip ${PACKAGE_URL}
unzip ${PACKAGE_TMP_DIR}/aepp-base-${VERSION}.zip -d ${PACKAGE_TMP_DIR}

aws s3 sync --acl public-read ${PACKAGE_TMP_DIR}/aepp-base-${VERSION} ${S3_BUCKET}
aws cloudfront create-invalidation --distribution-id ${CF_DISTRIBUTION_ID} --paths '/*'

printf "\nDone! Cache invalidation may take a while.\n"
