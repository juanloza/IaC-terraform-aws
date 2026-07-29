output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "s3_bucket_id" {
  description = "Name of the assets/backups bucket."
  value       = module.s3.bucket_id
}

output "ec2_autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = module.ec2.autoscaling_group_name
}

output "ec2_security_group_id" {
  description = "Security group ID of the application instances."
  value       = module.ec2.security_group_id
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port, no credentials)."
  value       = module.rds.endpoint
}

output "route53_zone_id" {
  description = "Hosted zone ID, or null when DNS is disabled."
  value       = var.create_dns ? module.route53[0].zone_id : null
}

output "route53_name_servers" {
  description = "Name servers to set at the registrar, or null when DNS is disabled."
  value       = var.create_dns ? module.route53[0].name_servers : null
}
