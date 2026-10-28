# --- Security groups ---

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Public entry point: HTTP and HTTPS from the internet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Web ECS tasks: reachable only from the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-web-sg"
  }
}

resource "aws_security_group" "worker" {
  name        = "${var.name}-worker-sg"
  description = "Worker ECS task: outbound only, no inbound"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-worker-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "RDS Postgres: reachable only from web and worker"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-db-sg"
  }
}

# --- Inbound ---

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTPS from anywhere"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTP from anywhere (redirected to HTTPS)"
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id            = aws_security_group.web.id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
  description                  = "App port from the ALB only"
}

resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id            = aws_security_group.db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
  description                  = "Postgres from web tasks"
}

resource "aws_vpc_security_group_ingress_rule" "db_from_worker" {
  security_group_id            = aws_security_group.db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.worker.id
  description                  = "Postgres from the worker"
}

# --- Outbound (DB has none: it only replies, and replies are allowed automatically) ---

resource "aws_vpc_security_group_egress_rule" "alb_to_vpc" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
  description       = "ALB to targets inside the VPC"
}

resource "aws_vpc_security_group_egress_rule" "web_all_out" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Web to the DB and AWS services (via NAT)"
}

resource "aws_vpc_security_group_egress_rule" "worker_all_out" {
  security_group_id = aws_security_group.worker.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Worker to the DB, AWS services and monitored sites (via NAT)"
}