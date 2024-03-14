
variable "network_name" {
  type = string
  default = "test-network"
}
variable "network_settings" {
  type = any
}
variable "subnets" {
  type = any
}
variable "internet_nat_gateway_routes" {
  type = any
  default = {}
}
variable "volume_security_group" {
  type = bool
  default = false
}

