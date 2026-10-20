variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "project name, used for naming the IAM role"
  type        = string
  default     = "vigilo"
}


variable "s3_bucket_name" {
  description = "the s3 bucket name"
  type        = string
  default     = "vigilo-tfstate-899259775765"
}

variable "github_owner" {
  description = "GitHub user that owns the repo"
  type        = string
  default     = "K-Othman"
}

variable "github_repo" {
  description = "Repository allowed to assume the CI roles"
  type        = string
  default     = "vigilo"
}

variable "hosted_zone_id" {
  description = "Route 53 zone for karimothman.co.uk; the apply role can only change records here"
  type        = string
  default     = "Z00153571R15NB2XXVOPZ"
}

variable "github_owner_id" {
  description = "Numeric GitHub account ID (part of the immutable OIDC subject)"
  type        = string
  default     = "101342241"
}

variable "github_repo_id" {
  description = "Numeric GitHub repo ID (part of the immutable OIDC subject)"
  type        = string
  default     = "1410984371"
}