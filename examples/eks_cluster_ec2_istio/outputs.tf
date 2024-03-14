output "cluster_controller_role_arn" {
    value = module.cluster.eks_load_balancer_controller_role.arn
}
output "cluster_vpc_id" {
    value = module.cluster.eks_cluster_vpc[0].vpc_id
}
output "default_security_group" {
    value = module.cluster.default_security_group.id
}
