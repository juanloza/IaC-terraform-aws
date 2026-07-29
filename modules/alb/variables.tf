variable "project" {
  description = "Project name, used for resource naming and tagging (e.g. \"acme-app\")."
  type        = string
}

variable "environment" {
  description = "Environment name, used for resource naming and tagging (e.g. \"example\", \"staging\", \"prod\")."
  type        = string
}

variable "vpc_id" {
  description = "VPC in which to create the load balancer, target group and security group (from the vpc module)."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to place the load balancer in. Use the public subnets for an internet-facing ALB (from the vpc module)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "An ALB requires at least two subnets in different availability zones."
  }
}

variable "internal" {
  description = "Whether the ALB is internal (no public IP). Default is internet-facing."
  type        = bool
  default     = false
}

variable "listener_port" {
  description = "Port the ALB listens on for HTTP."
  type        = number
  default     = 80
}

variable "app_port" {
  description = "Port the backend instances listen on (target group port). Should match the ec2 module's app_port."
  type        = number
  default     = 8080
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB listeners. Defaults to the whole internet, which is expected for a public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "health_check_path" {
  description = "HTTP path the target group health check requests."
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP status code(s) considered healthy (e.g. \"200\" or \"200-299\")."
  type        = string
  default     = "200"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN. When set, an HTTPS:443 listener is added and HTTP is redirected to HTTPS. Leave empty for an HTTP-only ALB (the example default, since the fictitious .example domain cannot be validated by ACM)."
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener (only used when acm_certificate_arn is set)."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  description = "Prevent the load balancer from being deleted. Enable in production."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout in seconds for connections."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Additional tags to merge onto every resource created by this module."
  type        = map(string)
  default     = {}
}
