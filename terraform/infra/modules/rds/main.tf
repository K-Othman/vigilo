# --- DB subnet group: the two private DB subnets (RDS needs two AZs) ---
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.name}-db-subnets"
  }
}

# --- PostgreSQL instance ---
resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "vigilo"
  username = "vigilo"

  # RDS generates the password and stores it in Secrets Manager (never in code or state)
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  multi_az               = false

  # The stack is destroyed nightly; the worker recreates tables and seed data on start
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.name}-db"
  }
}