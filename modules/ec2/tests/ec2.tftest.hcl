# Plan-time tests for the ec2 module (no AWS credentials, nothing created).

mock_provider "aws" {}

variables {
  project              = "acme-app"
  environment          = "test"
  vpc_id               = "vpc-0123456789abcdef0"
  subnet_ids           = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  iam_instance_profile = "acme-app-test-ec2-profile"
  ingress_cidr_blocks  = ["10.0.0.0/16"]
}

run "hardened_launch_template" {
  command = plan

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 (http_tokens = required) must be enforced"
  }

  assert {
    condition     = tostring(one(aws_launch_template.this.block_device_mappings).ebs[0].encrypted) == "true"
    error_message = "the root volume must be encrypted"
  }
}

run "rejects_public_ingress" {
  command = plan

  variables {
    ingress_cidr_blocks = ["0.0.0.0/0"]
  }

  expect_failures = [
    var.ingress_cidr_blocks,
  ]
}

run "requires_an_ingress_source" {
  command = plan

  variables {
    ingress_cidr_blocks   = []
    alb_security_group_id = ""
  }

  expect_failures = [
    aws_security_group.ec2,
  ]
}
