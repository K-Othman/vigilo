variable "name" {
  description = "Prefix for resource names and the Project tag"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the whole VPC"
  type        = string
}

variable "vpc_id" {
  description = "VPC the security groups belong to"
  type        = string
}