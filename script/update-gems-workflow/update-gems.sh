#!/bin/sh

# Updates the pact_broker gem in the image's lockfile.
#
# RubyGems does not always serve a just-published gem immediately, and this
# script runs seconds after the release. Retry rather than requiring someone to
# re-run the job by hand.

set -eu

cd pact_broker

attempts=5
delay=30

if [ -n "${RELEASED_GEM_NAME:-}" ] && [ -n "${RELEASED_GEM_VERSION:-}" ]; then
  n=1
  while true; do
    if gem install "${RELEASED_GEM_NAME}" -v "${RELEASED_GEM_VERSION}"; then
      break
    fi
    if [ "$n" -ge "$attempts" ]; then
      echo "${RELEASED_GEM_NAME} ${RELEASED_GEM_VERSION} still not available after ${attempts} attempts."
      exit 1
    fi
    echo "${RELEASED_GEM_NAME} ${RELEASED_GEM_VERSION} not available yet, retrying in ${delay}s (${n}/${attempts})."
    n=$((n + 1))
    sleep "$delay"
  done
  bundle update "${RELEASED_GEM_NAME}"
fi

bundle update
