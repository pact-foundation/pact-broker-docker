#!/usr/bin/env bash
# Publishes several versions, then waits for the scheduled clean to remove all
# but the latest. Exercises PACT_BROKER_DATABASE_CLEAN_* end to end.

set -euo pipefail

BASE_URL="${TEST_URL}"
LATEST_VERSION="1.0.5"

publish_version() {
  local version="$1"
  curl -sf -XPUT \
    -H "Content-Type: application/json" \
    -d@/home/foo-bar.json \
    "${BASE_URL}/pacts/provider/Bar/consumer/Foo/version/${version}" >/dev/null
}

# Fetches the versions list once. Echoes it on success; on any transient
# failure (the broker can be briefly unreachable mid-clean) echoes nothing
# and returns non-zero so callers can retry instead of aborting.
fetch_versions() {
  curl -sf -H "Accept: application/hal+json" "${BASE_URL}/pacticipants/Foo/versions"
}

version_count() {
  jq '._embedded.versions | length' <<<"$1"
}

survivor_version() {
  jq -r '._embedded.versions[0].number' <<<"$1"
}

echo "Publishing six versions of Foo"
for minor in 0 1 2 3 4 5; do
  publish_version "1.0.${minor}"
done

versions_json=$(fetch_versions)
initial=$(version_count "${versions_json}")
if [[ "${initial}" -ne 6 ]]; then
  echo "ERROR: expected 6 versions after publishing, got ${initial}" >&2
  exit 1
fi
echo "Confirmed ${initial} versions present"

echo "Waiting up to 180s for the scheduled clean to run"
remaining="${initial}"
deadline=$((SECONDS + 180))
while [[ ${SECONDS} -lt ${deadline} ]]; do
  if ! versions_json=$(fetch_versions); then
    sleep 5
    continue
  fi

  remaining=$(version_count "${versions_json}")
  if [[ "${remaining}" -eq 1 ]]; then
    survivor=$(survivor_version "${versions_json}")
    if [[ "${survivor}" == "${LATEST_VERSION}" ]]; then
      echo "SUCCESS: clean reduced 6 versions to 1 (survivor ${survivor})"
      exit 0
    fi
    echo "ERROR: clean left one version but it was ${survivor}, expected ${LATEST_VERSION}" >&2
    exit 1
  fi

  sleep 5
done

echo "ERROR: clean did not run; ${remaining} versions still present after 180s" >&2
exit 1
