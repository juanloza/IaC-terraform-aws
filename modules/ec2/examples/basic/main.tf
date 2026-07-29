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

module "ec2" {
  source = "../.."

  project     = "acme-app"
  environment = "example"

  # In a real composition these come from the vpc and iam modules.
  vpc_id               = "vpc-0123456789abcdef0"
  subnet_ids           = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  iam_instance_profile = "acme-app-example-ec2-profile"

  instance_type = "t3.micro"

  # No load balancer here: allow the application port only from the VPC CIDR.
  app_port            = 8080
  ingress_cidr_blocks = ["10.0.0.0/16"]

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  # AMI is looked up automatically (latest Amazon Linux 2023) when ami_id is empty.
}

variable "region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

output "autoscaling_group_name" {
  value = module.ec2.autoscaling_group_name
}

output "security_group_id" {
  value = module.ec2.security_group_id
}
