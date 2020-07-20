#!/bin/sh

set -euo

: "${TAG:?Please set the TAG environment variable}"
: "${RELEASED_GEM_NAME:?Please set the RELEASED_GEM_NAME environment variable}"
: "${RELEASED_GEM_VERSION:?Please set the RELEASED_GEM_VERSION environment variable}"

git add pact_broker/Gemfile.lock
git commit -m "feat(deps): update ${RELEASED_GEM_NAME} gem to version ${RELEASED_GEM_VERSION}"

bundle exec conventional-changelog version=${TAG}
git add CHANGELOG.md
git commit -m "chore(release): version ${TAG}"

git tag -a "${TAG}" -m "chore(release): version ${TAG}"
git push origin ${TAG} # Do this first so it fails if the tag already exists
git push origin master
