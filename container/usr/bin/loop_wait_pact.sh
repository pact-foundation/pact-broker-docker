#!/usr/bin/env bash

# This script
# - waits for the Pact Broker service heartbeat
# - needs to run inside the container

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

# requirements
if ! jq --version >/dev/null 2>&1 ; then
  die "Needs jq utility installed: https://stedolan.github.io/jq/download/"
fi

# defaults
[ -z "${PACT_BROKER_PORT}" ] && PACT_BROKER_PORT=80
[ -z "${PACT_BROKER_HOST}" ] && PACT_BROKER_HOST=localhost
USERNAME="$1"
PASSWORD="$2"

STATUS_URL="http://${PACT_BROKER_HOST}:${PACT_BROKER_PORT}/diagnostic/status/heartbeat"

if [ -n "${USERNAME}" ]; then
  CREDENTIALS="--user ${USERNAME}:${PASSWORD}"
else
  CREDENTIALS=""
fi
# Exit immediately if a command exits with a non-zero status
set -e

echo "STATUS_URL is '${STATUS_URL}'"
echo -n "Waiting for the Pact Broker to be ready..."
while ! curl -s ${CREDENTIALS} "${STATUS_URL}" | jq '.ok' | grep "true"; do
  echo -n '.'
  sleep 0.1
done
echo "Done $0"
