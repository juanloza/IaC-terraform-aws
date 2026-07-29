# Plan-time tests for the route53 module (no AWS credentials, nothing created).

mock_provider "aws" {}

variables {
  project     = "acme-app"
  environment = "test"
  domain_name = "acme-app.example"
}

run "creates_zone_by_default" {
  command = plan

  assert {
    condition     = length(aws_route53_zone.this) == 1
    error_message = "the hosted zone should be created when create_zone is true"
  }

  assert {
    condition     = length(data.aws_route53_zone.this) == 0
    error_message = "the zone data source should not be used when creating the zone"
  }
}

run "looks_up_existing_zone_when_disabled" {
  command = plan

  variables {
    create_zone = false
  }

  assert {
    condition     = length(aws_route53_zone.this) == 0
    error_message = "no zone should be created when create_zone is false"
  }

  assert {
    condition     = length(data.aws_route53_zone.this) == 1
    error_message = "the existing zone should be looked up when create_zone is false"
  }
}

run "creates_alias_and_cname_records" {
  command = plan

  variables {
    target_dns_name = "example-alb-1234567890.us-east-1.elb.amazonaws.com"
    target_zone_id  = "Z35SXDOTRQ7X7K"
    cname_records = {
      www = "acme-app.example"
    }
  }

  assert {
    condition     = length(aws_route53_record.alias) == 1
    error_message = "an alias record should be created when a target is provided"
  }

  assert {
    condition     = length(aws_route53_record.cname) == 1
    error_message = "one CNAME record should be created"
  }
}
