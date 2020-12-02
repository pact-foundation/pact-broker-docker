#/bin/sh

bundle exec rake pact_broker:db:clean
bundle exec rake pact_broker:db:delete_overwritten_data
