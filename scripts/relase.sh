#!/bin/bash
# should be run as:
# ./release.sh x.x.x
set -e

if [[ -n "$1" && "$1" =~ ^([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)*)$ ]]; then
    version=${1}
else
    echo specify a release version in format x.x.x e.g. ${0} 2.3.0 >&2; exit 1
fi

exit

