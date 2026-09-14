#!/bin/sh
# Asserts `docker stop` ends inside its grace period with the clean scheduler
# running. PID 1 is the entrypoint shell, so this holds only while it forwards
# SIGTERM to both children; a container that outlives the grace period was
# SIGKILLed and exits 137.

set -eu

: "${PACT_BROKER_IMAGE:?PACT_BROKER_IMAGE must be provided}"
export PACT_BROKER_IMAGE

GRACE=10
COMPOSE="docker compose -p pact-broker-shutdown -f test/compose/clean/compose.yml"

cleanup() {
  ${COMPOSE} rm -fsv >/dev/null 2>&1 || true
}
trap cleanup EXIT

${COMPOSE} up -d pact-broker

echo "Waiting for the broker to serve its heartbeat"
attempts=0
# Ruby is the one HTTP client both distros ship: the Debian runtime has neither
# wget nor curl.
heartbeat() {
  ${COMPOSE} exec -T pact-broker ruby -rnet/http -e \
    'exit Net::HTTP.get_response(URI("http://127.0.0.1:9292/diagnostic/status/heartbeat")).is_a?(Net::HTTPSuccess)' \
    2>/dev/null
}

until heartbeat; do
  attempts=$((attempts + 1))
  if [ "${attempts}" -ge 60 ]; then
    echo "FAIL: broker did not start" >&2
    ${COMPOSE} logs pact-broker >&2
    exit 1
  fi
  sleep 2
done

container=$(${COMPOSE} ps -q pact-broker)
started=$(date +%s)
${COMPOSE} stop -t "${GRACE}" pact-broker
elapsed=$(($(date +%s) - started))
exit_code=$(docker inspect -f '{{.State.ExitCode}}' "${container}")

if [ "${exit_code}" -eq 137 ] || [ "${elapsed}" -ge "${GRACE}" ]; then
  echo "FAIL: container took ${elapsed}s to stop and exited ${exit_code}; SIGTERM was not forwarded" >&2
  ${COMPOSE} logs pact-broker >&2
  exit 1
fi

echo "PASS: container stopped in ${elapsed}s with exit code ${exit_code}"
