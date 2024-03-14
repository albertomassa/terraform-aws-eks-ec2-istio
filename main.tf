
################################################################################
# EKS Cluster with EC2 Worker Nodes
################################################################################

module "network" {
    source                      = "./modules/network"
    network_name                = "${var.cluster_name}-network"
    network_settings            = {        
        cdir_vpc = var.network_config.cdir_vpc
        internet_gateway = true
        dns_support = true
    }
    subnets                     = var.network_config.subnets
    internet_nat_gateway_routes = var.network_config.nat_routes
}

resource "aws_eks_cluster" "cluster" {
  name                          =   var.cluster_name
  version                       =   var.cluster_version
  role_arn                      =   aws_iam_role.cluster-role.arn
  vpc_config                    {
    subnet_ids = [for subnet_id in values(module.network.subnets_ids) : subnet_id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
  ]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster-role" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_eks_node_group" "cluster_node_group" {
  cluster_name          = aws_eks_cluster.cluster.name
  node_role_arn         = aws_iam_role.cluster-ng-role.arn
  subnet_ids            = [for subnet_id in values(module.network.private_subnets_ids) : subnet_id]
  ami_type              = var.worker_nodes_config.ec2_conf.ami_type
  capacity_type         = var.worker_nodes_config.ec2_conf.capacity_type
  disk_size             = var.worker_nodes_config.ec2_conf.disk_size
  instance_types        = [var.worker_nodes_config.ec2_conf.instance_types]
  node_group_name       = var.worker_nodes_config.ec2_conf.node_group_name
  scaling_config {
    desired_size        = var.worker_nodes_config.autoscaling_conf.desired_size
    max_size            = var.worker_nodes_config.autoscaling_conf.max_size
    min_size            = var.worker_nodes_config.autoscaling_conf.min_size
  }
  update_config {
    max_unavailable     = var.worker_nodes_config.autoscaling_conf.max_unavailable
  }
  depends_on = [
    aws_iam_role_policy_attachment.cluster-ng-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.cluster-ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.cluster-ng-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "cluster-ng-role" {
  name = "${var.cluster_name}-cluster-ng-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cluster-ng-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.cluster-ng-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cluster-ng-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-ng-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cluster-ng-role.name
}

resource "aws_iam_policy" "istio_master_node_policy" {
    name = "${var.cluster_name}-AWSMasterNodeIstioIAMPolicy"
    path = "/"
    policy = file("iam_policy_istio.json")  
    depends_on  = [
        aws_eks_cluster.cluster,
        aws_eks_node_group.cluster_node_group
    ]
}

resource "aws_iam_role_policy_attachment" "cluster-ng-AWSMasterNodeIstioIAMPolicy" {
  policy_arn = aws_iam_policy.istio_master_node_policy.arn
  role       = aws_iam_role.cluster-ng-role.name
  depends_on = [
      aws_eks_cluster.cluster,
      aws_eks_node_group.cluster_node_group,
      aws_iam_policy.istio_master_node_policy
  ]  
}

resource "aws_iam_policy" "load_balancer_policy" {
    name = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
    path = "/"
    policy = file("iam_policy_ec2.json")  
    depends_on  = [
        aws_eks_cluster.cluster
    ]
}

data "tls_certificate" "cluster_tls_certificate" {
    url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_provider" {
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.cluster_tls_certificate.certificates[0].sha1_fingerprint]
    url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
    depends_on = [
        aws_eks_cluster.cluster
    ]
}

data "aws_iam_policy_document" "eks_policy_document" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_provider.url, "https://", "")}:sub"
      values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_provider.arn]
      type = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_load_balancer_controller_role" {
  assume_role_policy = data.aws_iam_policy_document.eks_policy_document.json
  name = "${var.cluster_name}-AmazonEKSLoadBalancerControllerRole"
}

resource "aws_iam_role_policy_attachment" "eks_load_balancer_controller_role_attachment" {
  role = aws_iam_role.eks_load_balancer_controller_role.name
  policy_arn = aws_iam_policy.load_balancer_policy.arn
}