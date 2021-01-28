#!/bin/sh

if [ "${PACT_BROKER_DATABASE_CLEAN_ENABLED}" = "true" ]; then
  echo "Creating crontab with schedule ${PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE} to clean database"
  echo "${PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE} clean" >> /pact_broker/crontab
  /usr/local/bin/supercronic -quiet -passthrough-logs /pact_broker/crontab &
fi

bundle exec puma
