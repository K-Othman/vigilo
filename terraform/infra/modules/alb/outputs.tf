output "target_group_arn" {
  description = "Target group the ECS web service registers its tasks in"
  value       = aws_lb_target_group.app.arn
}

output "alb_dns_name" {
  description = "ALB DNS name, for the Route 53 alias record"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID, for the Route 53 alias record"
  value       = aws_lb.main.zone_id
}