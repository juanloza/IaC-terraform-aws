output "alb_arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the load balancer (use as the Route 53 alias target_dns_name)."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the load balancer (use as the Route 53 alias target_zone_id)."
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ID of the ALB security group (pass to the ec2 module as alb_security_group_id)."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ARN of the target group (pass to the ec2 module as one of target_group_arns)."
  value       = aws_lb_target_group.this.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener, or null when HTTPS is not enabled."
  value       = local.https_enabled ? aws_lb_listener.https[0].arn : null
}
