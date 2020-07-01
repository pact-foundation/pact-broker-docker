#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# echo fn that outputs to stderr http://stackoverflow.com/a/2990533/511069
echoerr() {
  cat <<< "$@" 1>&2;
}

# print error and exit
die () {
  echoerr "ERROR: $0: $1"
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-115}
  exit $errnum
}

echo ""
echo "Checking that server accepts and return HTML from outside"
curl -H "Accept:text/html" --user ${PACT_BROKER_BASIC_AUTH_USERNAME}:${PACT_BROKER_BASIC_AUTH_PASSWORD} -s "${TEST_URL}"

echo ""
echo "Checking for specific HTML content from outside: 'Pacts'"
curl -H "Accept:text/html" --user ${PACT_BROKER_BASIC_AUTH_USERNAME}:${PACT_BROKER_BASIC_AUTH_PASSWORD} -s "${TEST_URL}" | grep "Pacts"

echo "Checking that server accepts and responds with status 200"
response_code=$(curl -s -o /dev/null -w "%{http_code}" --user ${PACT_BROKER_BASIC_AUTH_USERNAME}:${PACT_BROKER_BASIC_AUTH_PASSWORD} ${TEST_URL})

if [[ "${response_code}" -ne '200' ]]; then
  die "Expected response code to be 200, but was ${response_code}"
fi

if [[ ! -z "${PACT_BROKER_BASIC_AUTH_USERNAME}" ]]; then
  echo ""
  echo "Checking that basic auth is configured"
  response_code=$(curl -s -o /dev/null -w "%{http_code}" ${TEST_URL})

  if [[ "${response_code}" -ne '401' ]]; then
    die "Expected response code to be 401, but was ${response_code}"
  else
    echo "Correctly received a 401 for an unauthorised request"
  fi
fi

TEST_URL="http://pact-broker:${PACT_BROKER_PORT}"

curl -v -XPUT  \
  -u ${PACT_BROKER_BASIC_AUTH_USERNAME}:${PACT_BROKER_BASIC_AUTH_PASSWORD} \
  -H "Content-Type: application/json" \
  -d@/home/foo-bar.json \
  ${TEST_URL}/pacts/provider/Bar/consumer/Foo/version/1.1.0

echo ""
echo "Checking that badges can be accessed without basic auth"
response_code=$(curl -s -o /dev/null -w "%{http_code}" ${TEST_URL}/pacts/provider/Bar/consumer/Foo/latest/badge.svg)

if [[ "${response_code}" -ne '200' ]]; then
  die "Expected response code to be 200, but was ${response_code}"
fi

echo "Checking that the heartbeat URL can be accessed without basic auth"
response_code=$(curl -s -o /dev/null -w "%{http_code}" ${TEST_URL}/diagnostic/status/heartbeat)

if [[ "${response_code}" -ne '200' ]]; then
  die "Expected response code to be 200, but was ${response_code}"
fi

echo "SUCCESS: All tests passed!"
