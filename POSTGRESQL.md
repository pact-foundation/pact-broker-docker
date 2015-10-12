## Installation

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

## Setup DB

```
$ psql postgres
> create database pact_broker;
> CREATE USER pact_broker WITH PASSWORD 'pact_broker';
> GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker;
```

## Test connection

```bash
export PACT_BROKER_DATABASE_USERNAME=pact_broker
export PACT_BROKER_DATABASE_PASSWORD=pact_broker
export PACT_BROKER_DATABASE_NAME=pact_broker
export PACT_BROKER_DATABASE_HOST=192.168.0.XXX
psql -h $PACT_BROKER_DATABASE_HOST -d $PACT_BROKER_DATABASE_NAME -U $PACT_BROKER_DATABASE_USERNAME
```
