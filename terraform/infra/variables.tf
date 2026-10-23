variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Prefix for resource names and the Project tag"
  type        = string
  default     = "vigilo"
}

variable "repository_name" {
  description = "GitHub repo in owner/name form, used in the Repository tag"
  type        = string
  default     = "K-Othman/vigilo"
}

variable "vpc_cidr" {
  description = "CIDR range for the whole VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnets" {
  description = "Private app subnet CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnets" {
  description = "Private DB subnet CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}