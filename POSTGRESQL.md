The best way is to run postgresql via docker as well.

## Running Postgresql via Docker

1. Start the PostgreSQL container via:

  ```console
    $ docker run --name pactbroker-db -e POSTGRES_PASSWORD=ThePostgresPassword -e POSTGRES_USER=admin -e PGDATA=/var/lib/postgresql/data/pgdata -v /var/lib/postgresql/data:/var/lib/postgresql/data -d postgres
  ```

  Change ThePostgresPassword as required.

2. Connect to the container and execute psql via:

  ```console
    $ docker run -it --link pactbroker-db:postgres --rm postgres sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U admin'
  ```

  Run the follow SQL configuration scripts:

  ```sql
  CREATE USER pactbrokeruser WITH PASSWORD 'TheUserPassword';
  CREATE DATABASE pactbroker WITH OWNER pactbrokeruser;
  GRANT ALL PRIVILEGES ON DATABASE pactbroker TO pactbrokeruser;
  ```

3. Start the PactBroker container via:

    ```console
    $ docker run --name pactbroker --link pactbroker-db:postgres -e PACT_BROKER_DATABASE_USERNAME=pactbrokeruser -e PACT_BROKER_DATABASE_PASSWORD=TheUserPassword -e PACT_BROKER_DATABASE_HOST=postgres -e PACT_BROKER_DATABASE_NAME=pactbroker -d -p 9292:9292 dius/pact-broker
    ```

4. (Don't need to run this) Finally if you want to reconfigure/remove the container you will need to use

    ```console
    $ docker rm pactbroker-db
    $ docker rm pactbroker
    ```

## Installation of non-docker postgresql

If you want to use a non-docker installation of postgresql, follow theses instructions:

### Mac

```bash
brew install postgresql
vim ~/.bashrc
# Add: export PGDATA=/usr/local/var/postgres
. ~/.bashrc
pg_ctl start
```

### Enable remote connections

Instructions from: http://www.thegeekstuff.com/2014/02/enable-remote-postgresql-connection/

    $ vim /usr/local/var/postgres/pg_hba.conf

Replace `127.0.0.1/32` rule with:

```
host    all             all             0.0.0.0/0            trust
```

    $ vim /usr/local/var/postgres/postgresql.conf

Insert:

```
listen_addresses = '*'
```

    $ pg_ctl restart

### Setup DB

```
$ psql postgres
> create database pact_broker;
> CREATE USER pact_broker WITH PASSWORD 'pact_broker';
> GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker;
```

### Test connection

```bash
export PACT_BROKER_DATABASE_USERNAME=pact_broker
export PACT_BROKER_DATABASE_PASSWORD=pact_broker
export PACT_BROKER_DATABASE_NAME=pact_broker
export PACT_BROKER_DATABASE_HOST=192.168.0.XXX
psql postgresql://${PACT_BROKER_DATABASE_USERNAME}:${PACT_BROKER_DATABASE_PASSWORD}@${PACT_BROKER_DATABASE_HOST}/${PACT_BROKER_DATABASE_NAME}
```

