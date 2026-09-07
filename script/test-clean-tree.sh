#!/bin/sh
# Asserts the integration suite leaves the working tree unchanged.

set -eu

if [ -n "$(git status --porcelain -- '*.yml')" ]; then
  echo "FAIL: compose files were modified before the suite ran" >&2
  git status --porcelain -- '*.yml' >&2
  exit 1
fi

TAG="${TAG:-latest}" ./script/test.sh

if [ -n "$(git status --porcelain -- '*.yml')" ]; then
  echo "FAIL: the integration suite modified tracked compose files" >&2
  git status --porcelain -- '*.yml' >&2
  exit 1
fi

echo "PASS: working tree clean after integration suite"
