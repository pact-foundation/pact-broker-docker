#!/bin/sh

set -u

git fetch --all --tags

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  echo "Git tag ${TAG} already exists. Exiting."
  exit 1
fi

previous_release_in_changelog=$(cat CHANGELOG.md | grep "a name" | head -n 1 | cut -d'"' -f2)

if ! git rev-parse -q --verify "refs/tags/${previous_release_in_changelog}" >/dev/null; then
  echo "Previous release ${previous_release_in_changelog} listed in CHANGELOG.md does not have a corresponding tag. Exiting."
  exit 1
fi
