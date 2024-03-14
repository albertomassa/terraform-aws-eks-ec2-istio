output "eks_load_balancer_controller_role" {
    value = aws_iam_role.eks_load_balancer_controller_role
}
output "eks_cluster_vpc" {
    value = aws_eks_cluster.cluster.vpc_config
}
output "default_security_group" {
    value = module.network.default_security_group
}