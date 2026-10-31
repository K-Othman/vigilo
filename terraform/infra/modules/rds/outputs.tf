output "db_endpoint" {
  description = "Database hostname, used as DB_HOST"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Database port, used as DB_PORT"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name, used as DB_NAME"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Master username, used as DB_USER"
  value       = aws_db_instance.this.username
}

output "db_secret_arn" {
  description = "Secrets Manager secret holding the generated password"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}