#!/bin/sh

set -euo

: "${TAG:?Please set the TAG environment variable}"

bundle exec conventional-changelog version=${TAG}
git add CHANGELOG.md
git commit -m "chore(release): version ${TAG}"

git tag -a "${TAG}" -m "chore(release): version ${TAG}"
git push origin ${TAG} # Push to tag rather than master first so it fails if the tag already exists
