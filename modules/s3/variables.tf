variable "project" {
  description = "Project name, used for resource naming and tagging (e.g. \"acme-app\")."
  type        = string
}

variable "environment" {
  description = "Environment name, used for resource naming and tagging (e.g. \"example\", \"staging\", \"prod\")."
  type        = string
}

variable "bucket_suffix" {
  description = "Suffix appended to the bucket name to guarantee global uniqueness (S3 bucket names are globally unique). No default on purpose, so two deployments never collide."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_suffix))
    error_message = "bucket_suffix must contain only lowercase letters, digits and hyphens."
  }
}

variable "enable_versioning" {
  description = "Enable object versioning on the bucket."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm: \"AES256\" (SSE-S3, default) or \"aws:kms\" (SSE-KMS)."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be either \"AES256\" or \"aws:kms\"."
  }
}

variable "kms_key_id" {
  description = "KMS key ARN or ID to use when sse_algorithm is \"aws:kms\". Leave empty to use the AWS-managed aws/s3 key."
  type        = string
  default     = ""
}

variable "enable_lifecycle" {
  description = "Create the lifecycle configuration (IA transition + non-current version expiration)."
  type        = bool
  default     = true
}

variable "lifecycle_ia_transition_days" {
  description = "Number of days before current objects transition to STANDARD_IA."
  type        = number
  default     = 30
}

variable "lifecycle_noncurrent_expiration_days" {
  description = "Number of days before non-current object versions are expired (only meaningful with versioning enabled)."
  type        = number
  default     = 90
}

variable "logging_target_bucket" {
  description = "Name of an existing bucket to deliver S3 server access logs to. Leave empty to disable access logging (the default)."
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Key prefix for delivered access logs. Only used when logging_target_bucket is set."
  type        = string
  default     = "s3-access-logs/"
}

variable "tags" {
  description = "Additional tags to merge onto every resource created by this module."
  type        = map(string)
  default     = {}
}
