#!/bin/sh

set -euo

: "${TAG:?Please set the TAG environment variable}"

bundle exec conventional-changelog version=${TAG} force=true
git add CHANGELOG.md
git commit -m "chore(release): version ${TAG}"

git tag -a "${TAG}" -m "chore(release): version ${TAG}"
