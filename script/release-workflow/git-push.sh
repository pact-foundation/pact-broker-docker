#!/bin/sh

set -euo >/dev/null

git tag -a "${TAG}" -m "chore(release): version ${TAG}"
git push origin ${TAG}
git push origin master
