#!/bin/sh

if [ "${PACT_BROKER_DATABASE_BETA_CLEAN_ENABLED}" = "true" ]; then
  echo "Creating crontab with schedule ${PACT_BROKER_DATABASE_BETA_CLEAN_CRON_SCHEDULE} to clean database"
  echo "${PACT_BROKER_DATABASE_BETA_CLEAN_CRON_SCHEDULE} /pact_broker/clean.sh" >> /pact_broker/crontab
  /usr/local/bin/supercronic -quiet -passthrough-logs /pact_broker/crontab &
fi

bundle exec puma
