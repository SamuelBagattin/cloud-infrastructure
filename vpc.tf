locals {
  subnets_config = {
    "az1" = {
      cidr_block        = "172.31.0.0/20"
      availability_zone = "eu-west-3a"
    }
    "az2" = {
      cidr_block        = "172.31.16.0/20"
      availability_zone = "eu-west-3b"
    }
    "az3" = {
      cidr_block        = "172.31.32.0/20"
      availability_zone = "eu-west-3c"
    }
  }
  subnets_ids = [for o in aws_subnet.main : o.id]
  my_ip       = var.my_ip
}

resource "aws_default_vpc" "main" {
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" : "main"
  }
}

resource "aws_default_vpc_dhcp_options" "main" {
  tags = {
    Name : "main"
  }
}

resource "aws_subnet" "main" {
  for_each                = local.subnets_config
  map_public_ip_on_launch = true
  availability_zone       = each.value.availability_zone

  tags = {
    Name : "main-${each.key}"
  }
  cidr_block = each.value.cidr_block
  vpc_id     = aws_default_vpc.main.id
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_default_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name : "main"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_default_vpc.main.id
  tags = {
    Name : "main"
  }
}

resource "aws_default_network_acl" "main" {
  default_network_acl_id = aws_default_vpc.main.default_network_acl_id
  subnet_ids             = local.subnets_ids

  ingress {
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    from_port  = 0
    protocol   = "-1"
    rule_no    = 100
    to_port    = 0
  }

  egress {
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    from_port  = 0
    protocol   = "-1"
    rule_no    = 100
    to_port    = 0
  }

  tags = {
    Name : "main"
  }
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_default_vpc.main.id
  ingress {
    description = "From my ip"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["${var.my_ip}/32"]
  }
  egress {
    description = "To the internet"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name : "default"
  }
}

