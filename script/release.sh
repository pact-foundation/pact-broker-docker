#!/usr/bin/env bash

echo "Deprecated - the Docker Hub builds are turned off. Use script/trigger-release.sh" && exit 1

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
