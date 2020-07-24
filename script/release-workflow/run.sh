#!/bin/sh

set -euo >/dev/null

cd "$(dirname "$0")"

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  ./git-configure.sh
  ./docker-login.sh
fi

source ./set-env-vars.sh
./validate.sh
./docker-build.sh

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  bundle install
fi

./prepare-release.sh
./docker-push.sh
./git-push.sh
