output "module_vpc" {
  value = aws_vpc.vpc
}
output "module_subnets" {
  value = aws_subnet.subnet
}
output "subnets_ids" {
  value = {
    for k, v in aws_subnet.subnet : k => v.id
  }
}
output "private_subnets_ids" {
  value = {
     for k, v in aws_subnet.subnet : k => v.id if length(regexall(".*private.*", k)) > 0
  }
}
output "default_security_group" {
  value = aws_security_group.default_security_group
}