# environments/example

Root module that composes all six reusable modules into one deployable stack for
the fictitious `acme-app`. It is both a usage example and the target of the smoke
`terraform plan` in CI.

## How the modules are wired

```
vpc ──> public_subnet_ids ─────────────> alb
vpc ──> private_subnet_ids, vpc_id ─┬──> ec2
                                    └──> rds
s3  ──> bucket_arn ───────────────────> iam ──> ec2_instance_profile ──> ec2
alb ──> security_group_id, target_group_arn ──> ec2
ec2 ──> security_group_id ────────────> rds (allowed_security_group_id)
alb ──> dns_name, zone_id ────────────> route53 (apex alias)
```

Traffic path: internet → **alb** (public subnets) → **ec2** ASG (private subnets)
→ **rds** / **s3**. The ALB uses an HTTP listener by default; set the `alb` module's
`acm_certificate_arn` (for a domain you own) to enable HTTPS.

## ⚠️ Cost warning

Applying this environment creates billable resources. The main ongoing costs are:

- **NAT gateway** — per hour + per GB processed (one by default; more with
  `single_nat_gateway = false`).
- **RDS instance** — per hour + storage + backups (more with `db_multi_az = true`).
- EC2 instances in the ASG, plus small charges for storage, EIPs and CloudWatch logs.

This is **not** free-tier-only. Run `terraform destroy` as soon as you are done, and
never leave it running unattended.

## Prerequisites

- Terraform >= 1.7 and AWS credentials with permission to create the above.
- A globally unique `bucket_suffix`.

## Deploy

```bash
cd environments/example

# Provide the DB password out of band (never commit it):
export TF_VAR_db_password='choose-a-strong-password'

terraform init
terraform plan  -var-file=example.tfvars.example -var="bucket_suffix=<unique>"
terraform apply -var-file=example.tfvars.example -var="bucket_suffix=<unique>"

# When finished:
terraform destroy -var-file=example.tfvars.example -var="bucket_suffix=<unique>"
```

`terraform validate` runs without credentials; `plan`/`apply` need AWS credentials
because several data sources (latest AMI, caller identity) resolve against the account.

## State

State is local by default. For shared/remote state, configure the S3 + DynamoDB
backend in [`backend.tf`](./backend.tf) (bucket and lock table must already exist),
then run `terraform init -migrate-state`. State files are never committed
(`*.tfstate*` is git-ignored).

## Secrets

`db_password` has no default and is never stored in a committed file. Supply it via
`TF_VAR_db_password` or `-var`. Alternatively, switch the `rds` module to
`manage_master_user_password = true` to have RDS manage the password in AWS Secrets
Manager.
