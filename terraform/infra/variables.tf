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

