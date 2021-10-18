# k8s deployment example

## How to deploy

- Deploy infrastructure {IAM+DB} using tooling included for each AWS environment such as Test, UAT, Prod. Code is in `infrastructure` folder
- Then deploy k8s using Helm. This example doesn't impose opinion on how Helm is being run. Code is in `deployment` folder


## Assumptions

- K8s cluster is based on EKS
- K8s deployment is using Helm
- K8s pods can assume IAM role setup in this example (This is out of scope for this example though)

## Credits

It is created by Song.Jin at Xero.