output "alb_sg_id" {
  description = "Security group for alb"
  value       = aws_security_group.alb.id
}

output "web_sg_id" {
  description = "Security group for web ECS tasks"
  value       = aws_security_group.web.id
}

output "worker_sg_id" {
  description = "Security group for worker ECS task"
  value       = aws_security_group.worker.id
}

output "DB_sg_id" {
  description = "Security group for RDS"
  value       = aws_security_group.db.id
}