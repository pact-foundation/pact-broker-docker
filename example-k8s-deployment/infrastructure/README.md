# README

## How to deploy:

Run `./scripts/deploy_cfn.sh iam $ENVIRONMENT && ./scripts/deploy_cfn.sh db $ENVIRONMENT`

Script "deploy_cfn" utilises Docker-compose to run a Cloudformation tooling `Stackup`.

## Assumptions:

- K8s is based on AWS EKS service. (Hence the OIDC setup in IAM role
- AWS assumed role session is being represented by 3 env-vars {AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN}