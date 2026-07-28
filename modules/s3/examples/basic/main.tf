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

module "s3" {
  source = "../.."

  project     = "acme-app"
  environment = "example"

  # Must be globally unique; in a real deployment use a random suffix or an
  # account-specific token rather than a fixed value.
  bucket_suffix = "a1b2c3"
}

variable "region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

output "bucket_id" {
  value = module.s3.bucket_id
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}
