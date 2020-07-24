#!/bin/sh

set -euo

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
  git config --global user.name "${GITHUB_ACTOR}"
  git config --global push.default current

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
git push origin ${TAG}
git push origin master
