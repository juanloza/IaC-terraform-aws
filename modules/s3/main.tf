locals {
  name_prefix = "${var.project}-${var.environment}"
  bucket_name = "${local.name_prefix}-assets-${var.bucket_suffix}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

# Block every form of public access. These four flags together make it
# impossible to expose the bucket or its objects publicly by ACL or policy.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Server-side encryption is always on. SSE-S3 (AES256) is the default; pass
# sse_algorithm = "aws:kms" (optionally with kms_key_id) for SSE-KMS.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" && var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : null
  }
}

# Optional S3 server access logging. Off by default because it needs a separate
# destination bucket; enable it by passing logging_target_bucket.
resource "aws_s3_bucket_logging" "this" {
  count = var.logging_target_bucket != "" ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.this.id

  # Versioning status must settle before lifecycle rules that act on versions.
  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "transition-and-expire"
    status = "Enabled"

    filter {}

    transition {
      days          = var.lifecycle_ia_transition_days
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_noncurrent_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
