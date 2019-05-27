#!/bin/bash

set -Eeuo pipefail

if [ -z "$CIRCLE_BRANCH" -o "$CIRCLE_BRANCH" != "${NOTIFY_BRANCH:?}" ]; then
    exit 0
fi

payload()
{
  cat <<EOF
      {
        "text": "CircleCI job **${CIRCLE_JOB:?}** failed on branch **${CIRCLE_BRANCH:?}** by @${CIRCLE_USERNAME:-unknown}",
        "attachments": [
          {
            "title": "Build Link",
            "title_link": "${CIRCLE_BUILD_URL:?}",
            "color": "#FAD6D6"
          }
        ]
      }
EOF
}

curl -X POST -H 'Content-Type: application/json' ${ROCKET_HOOK_URL:?} --data "$(payload)"
