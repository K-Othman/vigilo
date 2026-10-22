# --- VPC ---
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# --- Public subnets: ALB nodes and NAT gateways ---
resource "aws_subnet" "public" {
  count             = length(var.vigilo_public_subnet)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vigilo_public_subnet[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Tier = "public"
  }
}

# --- Private app subnets: ECS tasks ---
resource "aws_subnet" "app" {
  count             = length(var.vigilo_app_private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vigilo_app_private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-app-${count.index + 1}"
    Tier = "app"
  }
}

# --- Private DB subnets: RDS ---
resource "aws_subnet" "db" {
  count             = length(var.vigilo_db_private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vigilo_db_private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-db-${count.index + 1}"
    Tier = "db"
  }
}

# --- Internet gateway ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}