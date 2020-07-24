#!/bin/sh

set -euo >/dev/null

cd pact_broker

if [ -n "${RELEASED_GEM_NAME:-}" ] && [ -n "${RELEASED_GEM_VERSION:-}" ]; then
  gem install ${RELEASED_GEM_NAME} -v ${RELEASED_GEM_VERSION}
  bundle update ${RELEASED_GEM_NAME}
fi

bundle update
