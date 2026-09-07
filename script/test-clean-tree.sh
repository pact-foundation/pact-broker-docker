#!/bin/sh
# Asserts the integration suite leaves the working tree unchanged.

set -eu

if grep -q "mysql2" pact_broker/Gemfile pact_broker/Gemfile.lock; then
  echo "FAIL: mysql2 is still present in the bundle" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "FAIL: the working tree was not clean before the suite ran" >&2
  git status --porcelain >&2
  exit 1
fi

TAG="${TAG:-latest}" ./script/test.sh

if [ -n "$(git status --porcelain)" ]; then
  echo "FAIL: the integration suite left the working tree dirty" >&2
  git status --porcelain >&2
  exit 1
fi

echo "PASS: working tree clean after integration suite"
