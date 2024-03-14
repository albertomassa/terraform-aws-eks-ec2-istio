variable "cluster_name" { type = string }
variable "project_region" { type = string }
variable "project_region_az1" { type = string }
variable "project_region_az2" { type = string }
variable "project_region_az3" { type = string }

output "cluster_name" { value = var.cluster_name }
output "project_region" { value = var.project_region }