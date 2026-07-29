# Plan-time tests for the vpc module. `mock_provider` means these run without AWS
# credentials and without creating anything.

mock_provider "aws" {
  # Return valid JSON for policy documents so resources that validate their
  # policy input (IAM roles) plan cleanly under the mock.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  project              = "acme-app"
  environment          = "test"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

run "single_nat_gateway_by_default" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway defaults to true, so exactly one NAT gateway is expected"
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "one public and one private subnet per AZ is expected"
  }
}

run "one_nat_gateway_per_az_when_disabled" {
  command = plan

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == length(var.azs)
    error_message = "with single_nat_gateway = false there should be one NAT gateway per AZ"
  }
}

run "rejects_mismatched_subnet_cidr_counts" {
  command = plan

  variables {
    public_subnet_cidrs = ["10.0.0.0/24"] # one CIDR for two AZs
  }

  expect_failures = [
    var.public_subnet_cidrs,
  ]
}
