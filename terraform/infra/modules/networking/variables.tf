variable "project_name" {
  description = "Prefix for resource names and the Project tag"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the whole VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across (one subnet per tier per AZ)"
  type        = list(string)
}

variable "vigilo_public_subnet" {
  description = "Public subnet CIDRs for the ALB and NAT gateways, one per AZ"
  type        = list(string)
}

variable "vigilo_app_private_subnets" {
  description = "Private app subnet CIDRs for ECS tasks, one per AZ"
  type        = list(string)
}

variable "vigilo_db_private_subnets" {
  description = "Private DB subnet CIDRs for RDS, one per AZ"
  type        = list(string)
}