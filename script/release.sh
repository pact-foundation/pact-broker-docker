#!/usr/bin/env bash

set -e

export TAG=$(script/release/next-docker-tag.sh)
echo "Releasing tag ${TAG}"
script/release/generate-changelog.sh
git add CHANGELOG.md && git commit -m "chore(changelog): update for ${TAG}
[ci-skip]"
echo "Tagging version ${TAG}"
git tag -a "${TAG}" -m "Releasing version ${TAG}"
git push origin "${TAG}"
git push origin master
echo "Releasing from https://hub.docker.com/repository/docker/pactfoundation/pact-broker/builds"

experimental_tag=$(script/release/next-docker-experimental-tag.sh)

echo "Tagging version ${experimental_tag}"
git tag -a "${experimental_tag}" -m "Releasing version ${experimental_tag}"
git push origin "${experimental_tag}"
