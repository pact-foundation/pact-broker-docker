#!/bin/sh

set -euo >/dev/null

git add pact_broker/Gemfile.lock

if [ -n "${RELEASED_GEM_NAME}" ] && [ -n "${RELEASED_GEM_VERSION}" ]; then
  git commit -m "feat(deps): update ${RELEASED_GEM_NAME} gem to version ${RELEASED_GEM_VERSION}

[ci-skip]
"
else
  updated_gems=$(git diff --staged pact_broker/Gemfile.lock | grep '^+' | grep '(' | sed -e "s/+ *//" | paste -sd "," - | sed -e 's/,/, /g')
  git commit -m "feat(deps): update to ${updated_gems}

[ci-skip]
"
fi

git push
