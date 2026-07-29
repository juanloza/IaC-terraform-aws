variable "project" {
  description = "Project name, used for resource naming and tagging (e.g. \"acme-app\")."
  type        = string
}

variable "environment" {
  description = "Environment name, used for resource naming and tagging (e.g. \"example\", \"staging\", \"prod\")."
  type        = string
}

# --- Placement ----------------------------------------------------------------

variable "vpc_id" {
  description = "VPC in which to create the instance security group (from the vpc module)."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs the Auto Scaling Group launches instances into (from the vpc module)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet is required."
  }
}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile to attach to the instances (from the iam module)."
  type        = string
}

# --- Instances ----------------------------------------------------------------

variable "ami_id" {
  description = "AMI ID for the instances. Leave empty to look up the latest Amazon Linux 2023 x86_64 AMI via a data source."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 20
}

variable "user_data" {
  description = "Cloud-init / shell script to run at boot. Passed as plain text; the module base64-encodes it. Keep application logic out of the module and pass it here."
  type        = string
  default     = ""
}

# --- Scaling ------------------------------------------------------------------

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}

# --- Networking / access ------------------------------------------------------

variable "app_port" {
  description = "Port the application listens on (used for the security group ingress rule)."
  type        = number
  default     = 8080
}

variable "alb_security_group_id" {
  description = "If set, instances accept traffic on app_port only from this security group (e.g. a load balancer). Takes precedence over ingress_cidr_blocks."
  type        = string
  default     = ""
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach app_port when no alb_security_group_id is given (typically the VPC CIDR). Must not include 0.0.0.0/0."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.ingress_cidr_blocks, "0.0.0.0/0")
    error_message = "ingress_cidr_blocks must not contain 0.0.0.0/0; the application port must never be open to the whole internet."
  }
}

variable "target_group_arns" {
  description = "Optional target group ARNs to attach the ASG to (for a load balancer added later)."
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "ASG health check type: \"EC2\" or \"ELB\"."
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be \"EC2\" or \"ELB\"."
  }
}

variable "tags" {
  description = "Additional tags to merge onto every resource created by this module."
  type        = map(string)
  default     = {}
}
