#!/bin/sh

set -euo >/dev/null

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  script/workflow/git-configure.sh
  script/workflow/docker-login.sh
fi

source script/workflow/set-env-vars.sh
script/workflow/validate.sh
script/workflow/docker-build.sh

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  bundle install
fi

script/workflow/prepare-release.sh
script/workflow/docker-push.sh
script/workflow/git-push.sh
