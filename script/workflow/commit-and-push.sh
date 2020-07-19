#!/bin/sh

set -euo pipefail

git add pact_broker/Gemfile.lock
git commit -m "feat(deps): update ${RELEASED_GEM_NAME} gem to version ${RELEASED_GEM_VERSION}"
git tag -a "${TAG}" -m "chore(release): version ${TAG}"
git push origin master --follow-tags
