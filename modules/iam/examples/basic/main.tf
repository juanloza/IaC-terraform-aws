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

module "iam" {
  source = "../.."

  project     = "acme-app"
  environment = "example"

  # In a real composition this ARN comes from the s3 module's bucket_arn output.
  s3_bucket_arn = "arn:aws:s3:::acme-app-example-assets"
}

variable "region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

output "ec2_instance_profile_name" {
  value = module.iam.ec2_instance_profile_name
}

output "ec2_role_arn" {
  value = module.iam.ec2_role_arn
}
