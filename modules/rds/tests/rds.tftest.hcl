# Plan-time tests for the rds module (no AWS credentials, nothing created).

mock_provider "aws" {}

variables {
  project                     = "acme-app"
  environment                 = "test"
  vpc_id                      = "vpc-0123456789abcdef0"
  subnet_ids                  = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  allowed_security_group_id   = "sg-0123456789abcdef0"
  manage_master_user_password = true
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "storage must always be encrypted"
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "the database must not be publicly accessible"
  }

  assert {
    condition     = aws_db_instance.this.multi_az == false
    error_message = "multi_az should default to false"
  }
}

run "requires_a_password_source" {
  command = plan

  variables {
    manage_master_user_password = false
    password                    = ""
  }

  expect_failures = [
    aws_db_instance.this,
  ]
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
