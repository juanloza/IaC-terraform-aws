locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  # Resolve the zone id whether the zone is created here or looked up.
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.this[0].zone_id

  name_servers = var.create_zone ? aws_route53_zone.this[0].name_servers : data.aws_route53_zone.this[0].name_servers

  # The alias record only makes sense once we know the target.
  create_alias = var.create_alias_record && var.target_dns_name != "" && var.target_zone_id != ""
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = var.domain_name
  })
}

data "aws_route53_zone" "this" {
  count = var.create_zone ? 0 : 1

  name = var.domain_name
}

# A/ALIAS record pointing the apex (or a subdomain) at the application entry
# point, e.g. a load balancer.
resource "aws_route53_record" "alias" {
  count = local.create_alias ? 1 : 0

  zone_id = local.zone_id
  name    = var.alias_record_name != "" ? "${var.alias_record_name}.${var.domain_name}" : var.domain_name
  type    = "A"

  alias {
    name                   = var.target_dns_name
    zone_id                = var.target_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# CNAME records, e.g. { www = "acme-app.example" }.
resource "aws_route53_record" "cname" {
  for_each = var.cname_records

  zone_id = local.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "CNAME"
  ttl     = var.cname_ttl
  records = [each.value]
}
