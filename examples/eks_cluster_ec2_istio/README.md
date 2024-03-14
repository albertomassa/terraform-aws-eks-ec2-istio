# EKS CLUSTER EC2 ISTIO (Example)

Below is a script that allows you to:

1. Run `terraform apply` for the Terraform module
2. Generate the `output.json` file, which will be used by the script to configure the infrastructure
3. Creation of the service account for the `aws-load-balancer-controller`
4. Installation of the `aws-load-balancer-controller` using Helm
5. Installation of Istio Service Mesh
6. Deployment of all YAML files located in the `platform` folder

ENJOY :-) 