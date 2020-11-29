#!/bin/sh

echo "Sleeping 10 seconds to ensure the postgres database is up and running. TODO: change this to poll"
sleep 10
/pact_broker/entrypoint.sh
