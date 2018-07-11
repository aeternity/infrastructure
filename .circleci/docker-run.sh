#/bin/bash

docker run --env-file ${CIRCLE_WORKING_DIRECTORY}/env.list ${DOCKERHUB_REPO:?}:${CIRCLE_BRANCH:?} "$@"
