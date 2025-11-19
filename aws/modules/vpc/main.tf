locals {
  name_prefix = "${var.name}"
}

resource "aws_vpc" "main" {
  region               = var.region
  cidr_block           = var.vpc_cidr

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

data "aws_availability_zones" "available" {}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, { Name = "${local.name_prefix}-igw" })
}

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : idx => cidr }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[each.key]
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${local.name_prefix}-public-${each.key}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]  # Changed this line

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-s3-endpoint"
  })
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${local.name_prefix}-ecs-tasks-sg"
  vpc_id = aws_vpc.main.id
 
  # JMeter RMI inbound from anywhere inside private subnet CIDR (master <-> slaves)
  ingress {
    description = "JMeter RMI port"
    from_port   = 1099
    to_port     = 1099
    protocol    = "tcp"
    self        = true
  }
 
  ingress {
    description = "JMeter master GUI port"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Restrict to VPC CIDR
  }
 
  # Allow all internal traffic between private instances for simplicity
  ingress {
    description = "All private SG internal communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
 
  # Allow all external traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = merge(var.tags, { Name = "${local.name_prefix}-sg" })
}