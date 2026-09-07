#!/usr/bin/env bash
# Publishes several versions, then waits for the scheduled clean to remove all
# but the latest. Exercises PACT_BROKER_DATABASE_CLEAN_* end to end.

set -euo pipefail

BASE_URL="${TEST_URL}"

publish_version() {
  local version="$1"
  curl -sf -XPUT \
    -H "Content-Type: application/json" \
    -d@/home/foo-bar.json \
    "${BASE_URL}/pacts/provider/Bar/consumer/Foo/version/${version}" >/dev/null
}

version_count() {
  curl -sf -H "Accept: application/hal+json" \
    "${BASE_URL}/pacticipants/Foo/versions" |
    jq '._embedded.versions | length'
}

echo "Publishing six versions of Foo"
for minor in 0 1 2 3 4 5; do
  publish_version "1.0.${minor}"
done

initial=$(version_count)
if [[ "${initial}" -ne 6 ]]; then
  echo "ERROR: expected 6 versions after publishing, got ${initial}" >&2
  exit 1
fi
echo "Confirmed ${initial} versions present"

echo "Waiting up to 180s for the scheduled clean to run"
deadline=$((SECONDS + 180))
while [[ ${SECONDS} -lt ${deadline} ]]; do
  remaining=$(version_count)
  if [[ "${remaining}" -eq 1 ]]; then
    echo "SUCCESS: clean reduced 6 versions to 1"
    exit 0
  fi
  sleep 5
done

echo "ERROR: clean did not run; ${remaining} versions still present after 180s" >&2
exit 1
