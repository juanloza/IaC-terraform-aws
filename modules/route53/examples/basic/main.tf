terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "route53" {
  source = "../.."

  project     = "acme-app"
  environment = "example"

  # Fictitious domain on the reserved .example TLD (RFC 2606). Never a real domain.
  domain_name = "acme-app.example"
  create_zone = true

  # In a real composition these come from the load balancer (or ec2 entry point).
  target_dns_name = "example-alb-1234567890.us-east-1.elb.amazonaws.com"
  target_zone_id  = "Z35SXDOTRQ7X7K"

  cname_records = {
    www = "acme-app.example"
  }
}

variable "region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

output "zone_id" {
  value = module.route53.zone_id
}

output "name_servers" {
  value = module.route53.name_servers
}
