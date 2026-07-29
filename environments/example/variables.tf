variable "aws_region" {
  description = "AWS region to deploy this environment into."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used for naming and tagging."
  type        = string
  default     = "acme-app"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "example"
}

# --- Network ------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to use. Must belong to aws_region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "One CIDR per AZ for the public subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "One CIDR per AZ for the private subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway (cheaper) instead of one per AZ."
  type        = bool
  default     = true
}

# --- Storage ------------------------------------------------------------------

variable "bucket_suffix" {
  description = "Suffix to make the S3 bucket name globally unique. Set to something account-specific."
  type        = string
}

# --- Compute ------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for the application ASG."
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Application port exposed by the instances (within the VPC)."
  type        = number
  default     = 8080
}

variable "min_size" {
  description = "ASG minimum size."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG maximum size."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "ASG desired capacity."
  type        = number
  default     = 1
}

# --- Database -----------------------------------------------------------------

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username."
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database master password. Never commit this: pass it via TF_VAR_db_password or -var. Leave manage_master_user_password to switch to Secrets Manager instead."
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Deploy the database across two AZs (higher cost)."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Database backup retention in days."
  type        = number
  default     = 7
}

# --- DNS ----------------------------------------------------------------------

variable "create_dns" {
  description = "Create the Route 53 hosted zone for domain_name."
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain for the hosted zone. Fictitious by default (.example is reserved, RFC 2606)."
  type        = string
  default     = "acme-app.example"
}
