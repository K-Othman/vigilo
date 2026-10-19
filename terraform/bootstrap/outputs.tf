output "apply_role_arn" {
  description = "Role for workflows on main (terraform apply)"
  value       = aws_iam_role.github_apply.arn
}

output "plan_role_arn" {
  description = "Role for pull request workflows (terraform plan)"
  value       = aws_iam_role.github_plan.arn
}

output "state_bucket_name" {
  description = "S3 bucket holding Terraform state"
  value       = aws_s3_bucket.bootstrap_s3_bucket.bucket
}