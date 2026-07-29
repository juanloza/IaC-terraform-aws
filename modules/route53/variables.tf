variable "project" {
  description = "Project name, used for tagging (e.g. \"acme-app\")."
  type        = string
}

variable "environment" {
  description = "Environment name, used for tagging (e.g. \"example\", \"staging\", \"prod\")."
  type        = string
}

variable "domain_name" {
  description = "Domain name for the hosted zone (e.g. \"acme-app.example\"). Use a domain you own; the repo example uses the reserved .example TLD (RFC 2606)."
  type        = string
}

variable "create_zone" {
  description = "Create the hosted zone (true) or look up an existing one by name via a data source (false)."
  type        = bool
  default     = true
}

# --- Apex alias record --------------------------------------------------------

variable "create_alias_record" {
  description = "Create an A/ALIAS record pointing at the application entry point (e.g. a load balancer). Requires target_dns_name and target_zone_id."
  type        = bool
  default     = true
}

variable "alias_record_name" {
  description = "Subdomain for the alias record; empty means the zone apex (domain_name itself). E.g. \"app\" produces app.<domain_name>."
  type        = string
  default     = ""
}

variable "target_dns_name" {
  description = "DNS name of the alias target (e.g. the load balancer's DNS name)."
  type        = string
  default     = ""
}

variable "target_zone_id" {
  description = "Hosted zone ID of the alias target (e.g. the load balancer's canonical hosted zone ID)."
  type        = string
  default     = ""
}

variable "evaluate_target_health" {
  description = "Whether the alias record evaluates the health of its target."
  type        = bool
  default     = true
}

# --- CNAME records ------------------------------------------------------------

variable "cname_records" {
  description = "CNAME records to create, as a map of subdomain => target (e.g. { www = \"acme-app.example\" })."
  type        = map(string)
  default     = {}
}

variable "cname_ttl" {
  description = "TTL in seconds for CNAME records."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional tags to merge onto the hosted zone (when created)."
  type        = map(string)
  default     = {}
}
