# Plan-time tests for the alb module (no AWS credentials, nothing created).

mock_provider "aws" {}

variables {
  project     = "acme-app"
  environment = "test"
  vpc_id      = "vpc-0123456789abcdef0"
  subnet_ids  = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

run "http_only_by_default" {
  command = plan

  assert {
    condition     = length(aws_lb_listener.https) == 0
    error_message = "no HTTPS listener should exist without an ACM certificate"
  }

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields == true
    error_message = "drop_invalid_header_fields must be enabled"
  }

  assert {
    condition     = aws_lb.this.internal == false
    error_message = "the ALB should be internet-facing by default"
  }
}

run "https_listener_when_certificate_set" {
  command = plan

  variables {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd-1234"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 1
    error_message = "an HTTPS listener should be created when acm_certificate_arn is set"
  }
}

run "requires_at_least_two_subnets" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [
    var.subnet_ids,
  ]
}
