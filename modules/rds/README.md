# rds

Managed PostgreSQL for the `acme-app` stack: a private, encrypted RDS instance in
the VPC's private subnets, reachable only from the application security group.

## What it configures

- **DB subnet group** across the private subnets you pass in (RDS needs ≥ 2 AZs).
- **Parameter group** for the chosen PostgreSQL family, with optional custom
  `parameters`.
- **Security group** whose only ingress is the application security group
  (`allowed_security_group_id`) on the DB port — no CIDR rules, no public access,
  and no egress.
- **DB instance**: `storage_encrypted = true` (always), `publicly_accessible = false`,
  automated backups (`backup_retention_period`), optional `multi_az`,
  `deletion_protection` and `skip_final_snapshot` per environment.

## Credentials — never commit a password

Two supported options:

1. **RDS-managed (recommended)**: set `manage_master_user_password = true` and RDS
   creates and rotates the master password in AWS Secrets Manager. No password ever
   lives in Terraform config or state input. The secret ARN is exposed as
   `master_user_secret_arn`.
2. **Supplied password**: pass `password` **via the `TF_VAR_db_password` environment
   variable** or an un-versioned `*.tfvars` file — never in a committed file. The
   variable is marked `sensitive`.

A `precondition` fails the plan if neither a password nor `manage_master_user_password`
is provided.

## Design notes

- Storage is always encrypted; `kms_key_id` selects a customer-managed key,
  otherwise the AWS-managed `aws/rds` key is used.
- `deletion_protection` and `skip_final_snapshot` default to the convenient
  throwaway-environment values (`false` / `true`). **Flip both for production**
  (`deletion_protection = true`, `skip_final_snapshot = false`).
- `multi_az = false` by default to save cost; enabling it adds a standby and
  roughly doubles the instance cost.
- The module declares no `provider` block; it inherits the AWS provider (and region)
  from the calling root module.

## Security scan notes

The important controls (encryption at rest, no public access, backups enabled,
security group scoped to the app tier) pass `tfsec`. A few hardening options are
left off by default and reported as non-blocking MEDIUM/LOW findings; only
HIGH/CRITICAL are treated as gating in this project. Enable them per environment
as needed:

- `deletion_protection` (MEDIUM) — off for throwaway environments; on for production.
- `iam_database_authentication_enabled` (MEDIUM) — off unless the app uses IAM tokens.
- `performance_insights_enabled` (LOW) — off to avoid cost.

## Cost warning

An always-on RDS instance bills per hour plus storage and backups; `multi_az` and
Performance Insights add more. Destroy environments you are not using.

## Usage

```hcl
module "rds" {
  source = "../../modules/rds"

  project     = "acme-app"
  environment = "example"

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnet_ids
  allowed_security_group_id = module.ec2.security_group_id

  engine_version          = "16"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  backup_retention_period = 7

  manage_master_user_password = true
  # or, instead: password = var.db_password  (from TF_VAR_db_password)
}
```

A runnable example lives in [`examples/basic`](./examples/basic).

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.7  |
| aws       | ~> 5.0  |

## Inputs

| Name                          | Type                              | Default        | Required | Description                                                        |
|-------------------------------|-----------------------------------|----------------|:--------:|--------------------------------------------------------------------|
| `project`                     | `string`                          | n/a            |   yes    | Project name, used for naming and tagging.                         |
| `environment`                 | `string`                          | n/a            |   yes    | Environment name.                                                  |
| `vpc_id`                      | `string`                          | n/a            |   yes    | VPC for the DB security group.                                     |
| `subnet_ids`                  | `list(string)`                    | n/a            |   yes    | Private subnet IDs (≥ 2 AZs) for the subnet group.                 |
| `allowed_security_group_id`   | `string`                          | n/a            |   yes    | The only security group allowed to connect (the ec2 module's SG).  |
| `port`                        | `number`                          | `5432`         |    no    | Database port.                                                     |
| `engine_version`              | `string`                          | `"16"`         |    no    | PostgreSQL engine version.                                         |
| `parameter_group_family`      | `string`                          | `"postgres16"` |    no    | Parameter group family (must match the engine version).            |
| `parameters`                  | `list(object({name,value}))`      | `[]`           |    no    | Custom DB parameters.                                              |
| `instance_class`              | `string`                          | `"db.t3.micro"`|    no    | Instance class.                                                    |
| `allocated_storage`           | `number`                          | `20`           |    no    | Initial storage (GB).                                              |
| `max_allocated_storage`       | `number`                          | `0`            |    no    | Storage autoscaling cap (GB); `0` disables autoscaling.            |
| `storage_type`                | `string`                          | `"gp3"`        |    no    | Storage type.                                                      |
| `kms_key_id`                  | `string`                          | `""`           |    no    | KMS key for encryption; empty uses `aws/rds`.                      |
| `db_name`                     | `string`                          | `"appdb"`      |    no    | Initial database name.                                             |
| `username`                    | `string`                          | `"appuser"`    |    no    | Master username.                                                   |
| `password`                    | `string` (sensitive)              | `""`           |    no    | Master password; supply via `TF_VAR_db_password`, never committed. |
| `manage_master_user_password` | `bool`                            | `false`        |    no    | Let RDS manage the password in Secrets Manager.                    |
| `multi_az`                    | `bool`                            | `false`        |    no    | Deploy a standby in a second AZ.                                   |
| `backup_retention_period`     | `number`                          | `7`            |    no    | Backup retention in days (> 0).                                    |
| `deletion_protection`         | `bool`                            | `false`        |    no    | Prevent deletion (enable in production).                           |
| `skip_final_snapshot`         | `bool`                            | `true`         |    no    | Skip final snapshot on destroy (set false in production).          |
| `performance_insights_enabled`| `bool`                            | `false`        |    no    | Enable Performance Insights.                                       |
| `iam_database_authentication_enabled` | `bool`                    | `false`        |    no    | Enable IAM database authentication (token-based logins).           |
| `tags`                        | `map(string)`                     | `{}`           |    no    | Extra tags merged onto every resource.                            |

## Outputs

| Name                     | Description                                                        |
|--------------------------|--------------------------------------------------------------------|
| `db_instance_id`         | RDS instance identifier.                                           |
| `db_instance_arn`        | RDS instance ARN.                                                  |
| `endpoint`               | `host:port` connection endpoint (no credentials).                 |
| `address`                | Instance hostname.                                                 |
| `port`                   | Database port.                                                     |
| `db_name`                | Initial database name.                                             |
| `security_group_id`      | Database security group ID.                                        |
| `master_user_secret_arn` | Secrets Manager ARN for the managed password (or `null`).         |
