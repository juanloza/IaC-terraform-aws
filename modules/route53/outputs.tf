output "zone_id" {
  description = "Hosted zone ID (created or looked up)."
  value       = local.zone_id
}

output "zone_name" {
  description = "Hosted zone domain name."
  value       = var.domain_name
}

output "name_servers" {
  description = "Name servers for the hosted zone. When the zone is created, set these at the domain registrar so the zone becomes authoritative."
  value       = local.name_servers
}

output "alias_record_fqdn" {
  description = "FQDN of the alias record, or null when no alias record was created."
  value       = local.create_alias ? aws_route53_record.alias[0].fqdn : null
}
