variable "project" {
  description = "Project name, used for resource naming and tagging (e.g. \"acme-app\")."
  type        = string
}

variable "environment" {
  description = "Environment name, used for resource naming and tagging (e.g. \"example\", \"staging\", \"prod\")."
  type        = string
}

# --- Networking ---------------------------------------------------------------

variable "vpc_id" {
  description = "VPC in which to create the database security group (from the vpc module)."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (from the vpc module). At least two in different AZs are required by RDS."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS requires at least two subnets in different availability zones."
  }
}

variable "allowed_security_group_id" {
  description = "Security group ID allowed to connect to the database (the ec2 module's security group). This is the only ingress source."
  type        = string
}

variable "port" {
  description = "Port the database listens on."
  type        = number
  default     = 5432
}

# --- Engine -------------------------------------------------------------------

variable "engine_version" {
  description = "PostgreSQL engine version (e.g. \"16.4\", or a major version like \"16\" to track the latest minor)."
  type        = string
  default     = "16"
}

variable "parameter_group_family" {
  description = "DB parameter group family, must match the engine version (e.g. \"postgres16\")."
  type        = string
  default     = "postgres16"
}

variable "parameters" {
  description = "Custom DB parameters to set on the parameter group."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# --- Sizing / storage ---------------------------------------------------------

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit in GB for storage autoscaling. Set to 0 to disable autoscaling."
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type (e.g. \"gp3\", \"gp2\")."
  type        = string
  default     = "gp3"
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption. Empty uses the AWS-managed aws/rds key. Storage is always encrypted."
  type        = string
  default     = ""
}

# --- Database / credentials ---------------------------------------------------

variable "db_name" {
  description = "Name of the initial database to create."
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "appuser"
}

variable "password" {
  description = "Master password. Never commit this: pass it via TF_VAR_db_password or an un-versioned tfvars file. Leave empty when manage_master_user_password is true."
  type        = string
  default     = ""
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Let RDS create and rotate the master password in AWS Secrets Manager instead of supplying `password`. Recommended over a static password."
  type        = bool
  default     = false
}

# --- Availability / backups / protection --------------------------------------

variable "multi_az" {
  description = "Deploy a standby in a second AZ for high availability (roughly doubles instance cost)."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups. Must be > 0 to keep backups enabled."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period > 0
    error_message = "backup_retention_period must be greater than 0 so automated backups stay enabled."
  }
}

variable "deletion_protection" {
  description = "Prevent the instance from being destroyed. Enable in production."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Convenient for throwaway environments; set to false in production."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights (adds cost). When enabled, encryption uses kms_key_id if set, otherwise the AWS-managed key."
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication (connect using IAM-issued tokens instead of a password). Requires application support."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge onto every resource created by this module."
  type        = map(string)
  default     = {}
}
