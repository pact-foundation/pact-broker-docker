#!/bin/bash
set -e

dump=/tmp/pg-dump.sql

if [ -f "${dump}" ]; then
  echo "Restoring dump from "${dump}""
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
      CREATE role pact_broker;
      GRANT ALL PRIVILEGES ON DATABASE postgres TO pact_broker;
  EOSQL

  pg_restore --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --clean --if-exists --no-privileges "${dump}"
else
  echo "Not restoring any dump file"
fi
