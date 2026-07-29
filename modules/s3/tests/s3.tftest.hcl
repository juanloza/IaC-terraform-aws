# Plan-time tests for the s3 module (no AWS credentials, nothing created).

mock_provider "aws" {}

variables {
  project       = "acme-app"
  environment   = "test"
  bucket_suffix = "abc123"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "acme-app-test-assets-abc123"
    error_message = "bucket name should be project-environment-assets-suffix"
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "all four public access block flags must be true"
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "versioning should be enabled by default"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "encryption should default to SSE-S3 (AES256)"
  }
}

run "rejects_invalid_bucket_suffix" {
  command = plan

  variables {
    bucket_suffix = "UPPER_case"
  }

  expect_failures = [
    var.bucket_suffix,
  ]
}
