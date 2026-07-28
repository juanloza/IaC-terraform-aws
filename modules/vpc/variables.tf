variable "project" {
  description = "Project name, used for resource naming and tagging (e.g. \"acme-app\")."
  type        = string
}

variable "environment" {
  description = "Environment name, used for resource naming and tagging (e.g. \"example\", \"staging\", \"prod\")."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. \"10.0.0.0/16\")."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  description = "Availability zones to spread subnets across (e.g. [\"us-east-1a\", \"us-east-1b\"]). At least two are recommended for high availability."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 1
    error_message = "azs must contain at least one availability zone."
  }
}

variable "public_subnet_cidrs" {
  description = "One CIDR block per availability zone for the public subnets. Must be the same length as azs."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs must have the same number of entries as azs (one CIDR per AZ)."
  }
}

variable "private_subnet_cidrs" {
  description = "One CIDR block per availability zone for the private subnets. Must be the same length as azs."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs must have the same number of entries as azs (one CIDR per AZ)."
  }
}

variable "single_nat_gateway" {
  description = "When true (default), a single shared NAT gateway is created for all private subnets (cheaper, single point of failure). When false, one NAT gateway is created per AZ (more expensive, more available)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "When true (default), VPC flow logs are captured to a CloudWatch log group via a dedicated least-privilege IAM role. Set to false to skip flow logs (and their CloudWatch ingestion cost)."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention in days for the VPC flow logs CloudWatch log group. Only used when enable_flow_logs is true."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to merge onto every resource created by this module."
  type        = map(string)
  default     = {}
}
