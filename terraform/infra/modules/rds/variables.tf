variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "db_subnet_ids" {
  description = "Private DB subnets, one per AZ"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Security group attached to the database"
  type        = string
}