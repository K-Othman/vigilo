variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC the target group belongs to"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets the ALB is placed in, one per AZ"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group attached to the ALB"
  type        = string
}

variable "certificate_arn" {
  description = "Validated ACM certificate for the HTTPS listener"
  type        = string
}