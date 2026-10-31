output "certificate_arn" {
  description = "ARN of the validated certificate, for the ALB HTTPS listener"
  value       = aws_acm_certificate.main.arn
}

output "zone_id" {
  description = "Hosted zone ID, reused for the app's DNS record"
  value       = data.aws_route53_zone.main.zone_id
}