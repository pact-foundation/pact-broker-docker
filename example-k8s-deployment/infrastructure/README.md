# README

## How to deploy:

Run `./scripts/deploy_cfn.sh iam $ENVIRONMENT && ./scripts/deploy_cfn.sh db $ENVIRONMENT`

Script "deploy_cfn" utilises Docker-compose to run a Cloudformation tooling `Stackup`.

## Assumptions:

- K8s is based on AWS EKS service. (Hence the OIDC setup in IAM role)