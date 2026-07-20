#!/bin/sh

# Send a lightweight, anonymous analytics ping (version + platform) to help us
# understand adoption of this image. Opt out with PACT_DO_NOT_TRACK or
# SCARF_NO_ANALYTICS. See https://docs.pact.io/telemetry for details.
if [ -z "${PACT_DO_NOT_TRACK:-}" ] && [ -z "${SCARF_NO_ANALYTICS:-}" ] \
  && [ -n "${PACT_BROKER_DOCKER_VERSION:-}" ] && [ -n "${PACT_BROKER_DOCKER_PLATFORM:-}" ]; then
  wget -q -T 2 -t 1 -O /dev/null "https://d.pactflow.io/pact-broker-docker/${PACT_BROKER_DOCKER_VERSION}/${PACT_BROKER_DOCKER_PLATFORM}" >/dev/null 2>&1 &
fi

if [ "${PACT_BROKER_DATABASE_CLEAN_ENABLED}" = "true" ]; then
  echo "Creating crontab with schedule ${PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE} to clean database"
  echo "${PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE} /usr/local/bin/clean" >> /pact_broker/crontab
  /usr/local/bin/supercronic -quiet -passthrough-logs /pact_broker/crontab &
fi

bundle exec puma
