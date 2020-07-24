#!/bin/sh

set -euo >/dev/null

bundle exec conventional-changelog version=${TAG} force=true
git add CHANGELOG.md
git commit -m "chore(release): version ${TAG}"
