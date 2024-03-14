# AWS EKS EC2 ISTIO Terraform module

A light and customizable Terraform Module to set up a complete infrastructure for an EKS cluster (IAM, network, security group, cluster, EC2 nodes, aws-load-balancer-controller) in High Availability. Inside the 'examples' folder, you can find a bash script that not only facilitates the apply process but also configures Istio service mesh and deploys a platform.

## Module Usage

```hcl

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.40.0"
    }
  }
}

provider "aws" { region = var.project_region }

module "eks" {
    source                    = "../"
    cluster_name              = var.cluster_name
    cluster_version           = "1.29"
    network_config            = {
      cdir_vpc = "20.0.0.0/24"  
      subnets  = {
        sub1_public = {
          cidr_block = "20.0.0.0/27"
          availability_zone = var.project_region_az1
          public_ip = true
          tags = {
              "kubernetes.io/role/elb" = "1"
              "kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        },
        sub1_private = {
          cidr_block = "20.0.0.32/27"
          availability_zone = var.project_region_az1
          public_ip = false
          tags = {
              "kubernetes.io/role/internal-elb" = "1"
              "kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        },
        sub2_public = {
          cidr_block = "20.0.0.64/27"
          availability_zone = var.project_region_az2
          public_ip = true
          tags = {
              "kubernetes.io/role/elb" = "1"
              "kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        },
        sub2_private = {
          cidr_block = "20.0.0.96/27"
          availability_zone = var.project_region_az2
          public_ip = false
          tags = {
              "kubernetes.io/role/internal-elb" = "1"
              "kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        },
        sub3_public = {
          cidr_block = "20.0.0.128/27"
          availability_zone = var.project_region_az3
          public_ip = true
          tags = {
              "kubernetes.io/role/elb" = "1"
              "kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        },
        sub3_private = {
          cidr_block = "20.0.0.160/27"
          availability_zone = var.project_region_az3
          public_ip = false
          tags = {
              "kubernetes.io/role/internal-elb" = "1"
              "kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        },
        sub4_services = {
          cidr_block = "20.0.0.192/26"
          availability_zone = var.project_region_az3
          public_ip = false
          tags = {
              "description" = ""
          }
        }
      }
      nat_routes = {
          sub1_public = "sub1_private"
          sub2_public = "sub2_private"
          sub3_public = "sub3_private"
      }
    }
    worker_nodes_config       = {
      ec2_conf = {
        ami_type = "AL2_x86_64"
        capacity_type = "ON_DEMAND"
        disk_size = 20
        instance_types = "t3.medium"
        node_group_name = "${var.cluster_name}-ng"
      }
      autoscaling_conf = {        
        desired_size = 3
        max_size = 9
        min_size = 2
        max_unavailable = 1
      }
    }
}

```


## Modules

| Name | Source | Description | Version |
|------|--------|---------|---------|
| <a name="network"></a> [network](#module\_eks\_managed\_node\_group) | ./modules/network | Configuration module for public and private subnets | n/a |


## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="cluster_name"></a> [cluster_name](#cluster_name) | The name of the eks cluster | `string` | `cluster-name` | no |
| <a name="cluster_version"></a> [cluster_version](#cluster_version) | Version of Kubernetes | `string` | `1.29` | no |
| <a name="cluster_version"></a> [cluster_version](#cluster_version) | Version of Kubernetes | `object` | n/a | yes |
| <a name="worker_nodes_config"></a> [worker_nodes_config](#worker_nodes_config) | Object with worker nodes configuration | `object` | n/a | yes |
| <a name="network_config"></a> [network_config](#network_config) | Object with network configuration | `object` | n/a | yes |

## Network Config Params

| Parameter Name       | Description                            | Required | Type             |
|----------------------|----------------------------------------|----------|------------------|
| subnets              | Subnets configuration                   | Yes      | `map<object>`     |
|   - sub1_public      | Public subnet | Yes  | `object`              |
|     - cidr_block    | Subnets CIDR Block                    | Yes      | `string`           |
|     - availability_zone | Subnets Availability Zone           | Yes      | `string`           |
|     - public_ip     | Indicates if the subnet is public      | Yes      | `boolean`          |
|     - tags           | Tags associated with the subnet        | Yes      | `map<string>`   |
|   - sub1_private     | Private subnet for var.project_region_az1 | Yes | `object`              |
|     - cidr_block    | Subnets CIDR Block                    | Yes      | `string`           |
|     - availability_zone | Subnets Availability Zone           | Yes      | `string`           |
|     - public_ip     | Indicates if the subnet is public      | Yes      | `boolean`          |
|     - tags           | Tags associated with the subnet        | Yes      | `map<string>`   |
|   ... (Analogous entries for other subnets)                 |         |                  |
| nat_routes           | Associations for NAT routes            | Yes      | `map<string,string>`   |

> **Important Note:**
> It is crucial that public subnets have names ending with _public, while private subnets should end with _private.

## Outputs

| Name | Description |
|------|-------------|
| <a name="eks_load_balancer_controller_role"></a> [eks_load_balancer_controller_role](#eks_load_balancer_controller_role) | Arn of the eks load balancer controller |
| <a name="eks_cluster_vpc"></a> [eks_cluster_vpc](#eks_cluster_vpcs) | VPC configuration |
| <a name="default_security_group"></a> [default_security_group](#default_security_group) | Arn of the security group |

# Author Information

## Name
Alberto Massa

## Biography
I'm a Sofware Architect & Technology Manager

## Contacts
- Email: albertomassa.info@gmail.com
- GitHub: [albertomassa](https://github.com/albertomassa)
- Facebook: [albertomassa.info](https://www.facebook.com/albertomassa.info)

## License

[MIT Licensed](https://en.wikipedia.org/wiki/MIT_License)


