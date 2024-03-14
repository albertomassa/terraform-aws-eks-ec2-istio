################################################################################
# EKS Network in HA for EKS Cluster
# Note - Use public and private subnets
################################################################################

resource "aws_vpc" "vpc" { 
  cidr_block                        = var.network_settings.cdir_vpc
  enable_dns_support                = var.network_settings.dns_support
  enable_dns_hostnames              = var.network_settings.dns_support
  assign_generated_ipv6_cidr_block  = true
  tags = {
    Name = var.network_name
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                        = aws_vpc.vpc.id
  for_each                      = var.subnets
  cidr_block                    = each.value.cidr_block
  availability_zone             = each.value.availability_zone
  map_public_ip_on_launch       = each.value.public_ip
  depends_on = [
    aws_vpc.vpc
  ]
  tags = "${merge(each.value.tags, 
              tomap({"Name" =  "${var.network_name}-subnet-${each.key}"})
          )}"
}

resource "aws_internet_gateway" "i_gateway" {
  count           = var.network_settings.internet_gateway == true ? 1 : 0
  vpc_id          = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    Name = "${var.network_name}-igateway"
  }
}

resource "aws_route_table" "i_gateway_route" {
  count         = var.network_settings.internet_gateway == true ? 1 : 0
  vpc_id        = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.i_gateway[0].id
  }
  depends_on = [
    aws_vpc.vpc, 
    aws_internet_gateway.i_gateway
  ]
  tags = {
    Name = "${var.network_name}-route-table-igateway"
  }
}

resource "aws_route_table_association" "i_gateway_route_association" {
  for_each          = var.internet_nat_gateway_routes
  subnet_id         = aws_subnet.subnet[each.key].id
  route_table_id    = aws_route_table.i_gateway_route[0].id
  depends_on = [
    aws_route_table.i_gateway_route,
    aws_subnet.subnet
  ]
}

resource "aws_eip" "eip" {
  for_each        = var.internet_nat_gateway_routes
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    Name = "${var.network_name}-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  for_each            = var.internet_nat_gateway_routes
  allocation_id       = aws_eip.eip[each.key].id
  subnet_id           = aws_subnet.subnet[each.key].id
  depends_on = [
    aws_eip.eip,
    aws_subnet.subnet
  ]
  tags = {
    Name = "${var.network_name}-nat-gateway-${each.key}"
  }
}

resource "aws_route_table" "nat_gateway_route" {
  for_each            = var.internet_nat_gateway_routes
  vpc_id              = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[each.key].id
  }
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.nat_gateway
  ]
  tags = {
    Name = "${var.network_name}-nat-gateway-route-${each.key}"
  }
}

resource "aws_route_table_association" "nat_gateway_route_association" {
  for_each              = var.internet_nat_gateway_routes
  subnet_id             = aws_subnet.subnet[each.value].id
  route_table_id        = aws_route_table.nat_gateway_route[each.key].id
  depends_on = [
    aws_route_table.nat_gateway_route,
    aws_subnet.subnet
  ]
}

resource "aws_security_group" "default_security_group" {
    vpc_id              = aws_vpc.vpc.id
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port = 6379
      to_port = 6379
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"] 
    }
    egress {
      from_port       = 0
      to_port         = 65535
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
    }
    depends_on = [
      aws_vpc.vpc
    ]
    tags = {
      Name = "${var.network_name}-default-security-group"
    }
}