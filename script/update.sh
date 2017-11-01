#!/usr/bin/env sh

set -e

cd pact_broker
bundle update
cd ..
PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite script/test.sh
PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite script/test_basic_auth.sh
git add pact_broker
git commit -m "feat(gems): update pact_broker gem to version $(cd pact_broker && bundle exec ruby -e "require 'pact_broker/version'; puts PactBroker::VERSION")"
git push
