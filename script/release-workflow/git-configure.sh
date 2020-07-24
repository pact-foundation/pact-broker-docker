#!/bin/sh

set -euo >/dev/null

git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --global user.name "${GITHUB_ACTOR}"
git config --global push.default current
