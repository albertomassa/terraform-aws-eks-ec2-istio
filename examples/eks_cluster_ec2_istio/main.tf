terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.40.0"
    }
  }
}

provider "aws" { region = var.project_region }

module "cluster" {
    source                    = "../.."
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
      nat_routes      = {
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

