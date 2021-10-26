# README

This folder contains config files for Helm Chart "Generic-services".

When using, ensure to load both config files `common.yaml` and `[environment].yaml`. Common.yaml contains common configs across all envs, while [environment].yaml contains environment-specific configs.

## Assumptions

- Helm value `image.tag` and `image.repository` has been injected by your Helm tooling

## Intentional omissions

- This example doesn't impose opinion on how Docker image for Pact Broker has been built and published.

- It is assumed that config `pact-broker-db-connection-string` has been setup in AWS Secret-Manager and been made available as env-var for k8s pod, following this format `postgres://pact_broker_user:pact_broker_password@pact_broker_db_host/pact_broker`. This example doesn't want to impose opinion on how to retrieve Secret-Manager secret `DB password` as part of secret-management scheme for k8s, as different organisations have their own secret-management plan already in place.