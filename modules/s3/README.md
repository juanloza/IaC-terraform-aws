# s3

Object storage bucket for the `acme-app` stack — application assets and backups —
with versioning, lifecycle rules, encryption at rest and **all public access
blocked**. Its `bucket_arn` output is what the `iam` module scopes the EC2 role to.

## What it configures

- **Public access block** with all four flags on (`block_public_acls`,
  `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`), so the
  bucket can never be made public by ACL or policy.
- **Versioning** enabled by default (`enable_versioning`).
- **Encryption at rest**, always on: SSE-S3 (`AES256`) by default, or SSE-KMS via
  `sse_algorithm = "aws:kms"` (and optionally `kms_key_id`).
- **Lifecycle** (`enable_lifecycle`, on by default): current objects transition to
  `STANDARD_IA` after `lifecycle_ia_transition_days`, non-current versions expire
  after `lifecycle_noncurrent_expiration_days`, and incomplete multipart uploads
  are aborted after 7 days.

## Design notes

- **Bucket name** is `${project}-${environment}-assets-${bucket_suffix}`.
  `bucket_suffix` is required (no default) because S3 bucket names are globally
  unique — a shared default would collide across accounts.
- Serving assets publicly should be done through a CDN (CloudFront) in front of the
  private bucket, not by opening the bucket. CloudFront is out of scope here.
- The module declares no `provider` block; it inherits the AWS provider (and region)
  from the calling root module.
- **Access logging** is opt-in via `logging_target_bucket` (it needs a separate
  destination bucket). With it disabled, `tfsec` reports a non-blocking MEDIUM
  (`aws-s3-enable-bucket-logging`); only HIGH/CRITICAL findings are treated as
  gating in this project.

## Usage

```hcl
module "s3" {
  source = "../../modules/s3"

  project     = "acme-app"
  environment = "example"

  bucket_suffix = "a1b2c3" # globally unique

  # Optional:
  # sse_algorithm                        = "aws:kms"
  # kms_key_id                           = "arn:aws:kms:us-east-1:123456789012:key/..."
  # lifecycle_ia_transition_days         = 30
  # lifecycle_noncurrent_expiration_days = 90
}

# Feed the ARN into the iam module:
#   s3_bucket_arn = module.s3.bucket_arn
```

A runnable example lives in [`examples/basic`](./examples/basic).

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.7  |
| aws       | ~> 5.0  |

## Inputs

| Name                                   | Type          | Default    | Required | Description                                                            |
|----------------------------------------|---------------|------------|:--------:|------------------------------------------------------------------------|
| `project`                              | `string`      | n/a        |   yes    | Project name, used for naming and tagging.                             |
| `environment`                          | `string`      | n/a        |   yes    | Environment name (e.g. `example`, `staging`, `prod`).                  |
| `bucket_suffix`                        | `string`      | n/a        |   yes    | Suffix for global bucket-name uniqueness (lowercase/digits/hyphens).   |
| `enable_versioning`                    | `bool`        | `true`     |    no    | Enable object versioning.                                              |
| `sse_algorithm`                        | `string`      | `"AES256"` |    no    | `AES256` (SSE-S3) or `aws:kms` (SSE-KMS).                              |
| `kms_key_id`                           | `string`      | `""`       |    no    | KMS key for SSE-KMS; empty uses the AWS-managed `aws/s3` key.          |
| `enable_lifecycle`                     | `bool`        | `true`     |    no    | Create the lifecycle configuration.                                    |
| `lifecycle_ia_transition_days`         | `number`      | `30`       |    no    | Days before objects transition to `STANDARD_IA`.                       |
| `lifecycle_noncurrent_expiration_days` | `number`      | `90`       |    no    | Days before non-current versions expire.                              |
| `logging_target_bucket`                | `string`      | `""`       |    no    | Destination bucket for S3 access logs; empty disables access logging.  |
| `logging_target_prefix`                | `string`      | `"s3-access-logs/"` | no | Key prefix for delivered access logs.                                  |
| `tags`                                 | `map(string)` | `{}`       |    no    | Extra tags merged onto every resource.                                 |

## Outputs

| Name                          | Description                                              |
|-------------------------------|----------------------------------------------------------|
| `bucket_id`                   | Bucket name (ID).                                        |
| `bucket_arn`                  | Bucket ARN (consumed by the `iam` module).              |
| `bucket_regional_domain_name` | Regional domain name of the bucket.                     |
