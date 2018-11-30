#/bin/bash

docker run --rm --env-file ${CIRCLE_WORKING_DIRECTORY}/env.list ${DOCKERHUB_REPO:?}:${CIRCLE_BRANCH:?} "$@"
