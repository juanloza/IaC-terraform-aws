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

module "rds" {
  source = "../.."

  project     = "acme-app"
  environment = "example"

  # In a real composition these come from the vpc and ec2 modules.
  vpc_id                    = "vpc-0123456789abcdef0"
  subnet_ids                = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  allowed_security_group_id = "sg-0123456789abcdef0"

  # Use RDS-managed credentials in Secrets Manager, so no password is ever
  # written into configuration.
  manage_master_user_password = true
}

variable "region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

output "endpoint" {
  value = module.rds.endpoint
}

output "security_group_id" {
  value = module.rds.security_group_id
}
