variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "Region for the awslogs driver"
  type        = string
}

variable "image" {
  description = "Full image URI with its immutable SHA tag"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private app subnets the tasks run in"
  type        = list(string)
}

variable "web_sg_id" {
  description = "Security group for web tasks"
  type        = string
}

variable "worker_sg_id" {
  description = "Security group for the worker task"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group the web service registers in"
  type        = string
}

variable "db_endpoint" {
  description = "Database hostname (DB_HOST)"
  type        = string
}

variable "db_port" {
  description = "Database port (DB_PORT)"
  type        = number
}

variable "db_name" {
  description = "Database name (DB_NAME)"
  type        = string
}

variable "db_username" {
  description = "Database user (DB_USER)"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager secret holding the DB password"
  type        = string
}