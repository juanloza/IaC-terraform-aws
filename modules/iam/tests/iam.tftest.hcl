# Plan-time tests for the iam module (no AWS credentials, nothing created).

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  project       = "acme-app"
  environment   = "test"
  s3_bucket_arn = "arn:aws:s3:::acme-app-test-assets"
}

run "creates_role_and_instance_profile" {
  command = plan

  assert {
    condition     = aws_iam_role.ec2.name == "acme-app-test-ec2-role"
    error_message = "role name should follow the project-environment convention"
  }

  assert {
    condition     = aws_iam_instance_profile.ec2.name == "acme-app-test-ec2-profile"
    error_message = "instance profile name should follow the project-environment convention"
  }
}

run "rejects_invalid_bucket_arn" {
  command = plan

  variables {
    s3_bucket_arn = "not-an-arn"
  }

  expect_failures = [
    var.s3_bucket_arn,
  ]
}
