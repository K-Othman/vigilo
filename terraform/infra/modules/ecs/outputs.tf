output "cluster_name" {
  description = "ECS cluster name, for the deploy pipeline"
  value       = aws_ecs_cluster.main.name
}

output "web_service_name" {
  description = "Web service name"
  value       = aws_ecs_service.web.name
}

output "worker_service_name" {
  description = "Worker service name"
  value       = aws_ecs_service.worker.name
}