variable "project" {
  description = "Project name, used for resource naming and tagging (e.g. \"acme-app\")."
  type        = string
}

variable "environment" {
  description = "Environment name, used for resource naming and tagging (e.g. \"example\", \"staging\", \"prod\")."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket the EC2 role is allowed to access (comes from the s3 module). The role gets object read/write and bucket listing on this bucket only."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9.-]+$", var.s3_bucket_arn))
    error_message = "s3_bucket_arn must be a valid S3 bucket ARN, e.g. \"arn:aws:s3:::acme-app-example-assets\"."
  }
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group the EC2 role may write to. Leave empty to scope permissions to log groups matching '/<project>/<environment>/*' in the current account and region."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to merge onto every resource created by this module."
  type        = map(string)
  default     = {}
}
