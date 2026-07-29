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

module "alb" {
  source = "../.."

  project     = "acme-app"
  environment = "example"

  # In a real composition these come from the vpc module (public subnets).
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  app_port          = 8080
  health_check_path = "/health"

  # HTTP only here; set acm_certificate_arn to add an HTTPS listener + redirect.
}

variable "region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "target_group_arn" {
  value = module.alb.target_group_arn
}
