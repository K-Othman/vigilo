# --- VPC ---
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

# --- Public subnets: ALB nodes and NAT gateways ---
resource "aws_subnet" "public" {
  count             = length(var.vigilo_public_subnet)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vigilo_public_subnet[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
  }
}

# --- Private app subnets: ECS tasks ---
resource "aws_subnet" "app" {
  count             = length(var.vigilo_app_private_subnet)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vigilo_app_private_subnet[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-app-${count.index + 1}"
    Tier = "app"
  }
}

# --- Private DB subnets: RDS ---
resource "aws_subnet" "db" {
  count             = length(var.vigilo_db_private_subnet)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vigilo_db_private_subnet[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-db-${count.index + 1}"
    Tier = "db"
  }
}

# --- Internet gateway ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# --- Allocate an Elastic IP ---
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}


# --- NAT Gateway in the public subnet ---
resource "aws_nat_gateway" "main" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name}-nat-gateway-${count.index + 1}"
  }
}


# --- Route table with internet access ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

# --- App route table ---
resource "aws_route_table" "app" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.name}-app-rt-${count.index + 1}"
  }
}

# --- DB route table ---
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id


  tags = {
    Name = "${var.name}-db-rt"
  }
}

# --- Public subnets associations ---
resource "aws_route_table_association" "public" {
  count          = length(var.vigilo_public_subnet)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- App subnets associations ---
resource "aws_route_table_association" "app" {
  count          = length(var.vigilo_app_private_subnet)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}


# --- DB subnets associations ---
resource "aws_route_table_association" "db" {
  count          = length(var.vigilo_db_private_subnet)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

