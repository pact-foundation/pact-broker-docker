#!/bin/sh

bundle exec rake pact_broker:db:migrate[$PACT_BROKER_MIGRATION_TARGET]
