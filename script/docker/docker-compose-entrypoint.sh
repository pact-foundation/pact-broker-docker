#!/bin/sh

echo "Sleeping 15 seconds to ensure the postgres database is up and running. TODO: change this to poll"
sleep 15
/pact_broker/entrypoint.sh
