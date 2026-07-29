# terraform-aws-modules

Reusable Terraform modules for provisioning a typical AWS-based web application stack: networking, compute, a managed relational database, object storage, DNS, and IAM roles — written as versioned Infrastructure as Code instead of manual console management.

## Motivation

This project formalizes, as reusable IaC, the kind of AWS setup commonly run in production for a small-to-medium web application: a VPC with public/private subnets, EC2 instances behind a load balancer, a managed PostgreSQL database, an S3 bucket for assets/backups, Route 53 for DNS, and IAM roles following least privilege. The reference scenario used throughout (`acme-app`) is fictitious; no real client or employer data, domains, or credentials are used anywhere in this repository.

## Modules

| Module | Purpose |
|---|---|
| `modules/vpc` | VPC, public/private subnets across multiple AZs, internet/NAT gateways, route tables |
| `modules/iam` | Least-privilege IAM roles and policies for compute and storage access |
| `modules/ec2` | Launch template + Auto Scaling Group (or standalone instances) for application compute |
| `modules/alb` | Internet-facing Application Load Balancer, target group and listeners (HTTP, optional HTTPS) |
| `modules/rds` | Managed PostgreSQL instance, subnet group, parameter group, automated backups |
| `modules/s3` | Versioned S3 bucket with lifecycle rules for assets/backups |
| `modules/route53` | Hosted zone and DNS records pointing at the app's load balancer |

## Repository structure

```
terraform-aws-modules/
├── modules/            # one directory per reusable module (see table above)
├── environments/       # root modules that compose the above per environment (e.g. example/)
└── .github/workflows/  # CI: fmt, validate, lint, security scan, secrets, plan
```

Each module is self-contained (its own `variables`, `outputs`, `versions`,
`README.md`, `examples/` and `tests/`) and can be consumed independently. The
`environments/` root modules wire the modules together into a deployable stack.

## Conventions

- **Naming**: resources are named `${project}-${environment}-<resource>`
  (e.g. `acme-app-example-vpc`).
- **Tagging**: every resource carries `Project`, `Environment` and
  `ManagedBy = "terraform"`, plus any extra tags passed via a `tags` variable.
- **Composition over duplication**: modules receive what they need through input
  variables (e.g. `vpc_id`, `subnet_ids`) rather than looking resources up by
  hard-coded names; environments are thin root modules that instantiate the
  reusable modules with concrete values.
- **No provider blocks in modules**: modules inherit the AWS provider (and region)
  from the calling root module.
- **Least privilege & no static secrets**: IAM policies are scoped to specific
  ARNs (no `Resource: "*"`), EC2 access is granted through instance profiles
  (temporary credentials), and sensitive values such as database passwords are
  never committed — they are passed via `TF_VAR_*` environment variables or an
  un-versioned `*.tfvars` file.

## State management

Terraform state is intended to live in a remote backend (S3 for storage +
DynamoDB for locking), configured per environment under `environments/<name>/backend.tf`.
No state files are committed — `*.tfstate*` is git-ignored.

## Reference scenario

Everything uses a fictitious company, **`acme-app`**, and the reserved
documentation domain `acme-app.example` (RFC 2606). No real account IDs, domains,
IPs or credentials appear anywhere in this repository.

## Requirements

- Terraform >= 1.7
- An AWS account (a free-tier/sandbox account is enough to validate `plan`; `apply` incurs cost, particularly for NAT gateways and RDS)
- AWS credentials configured locally (or, in CI, short-lived credentials obtained
  via GitHub OIDC — no static access keys)

## Usage

Compose the modules through the example environment:

```bash
cd environments/example

export TF_VAR_db_password='choose-a-strong-password'   # never commit this
terraform init
terraform plan  -var-file=example.tfvars.example -var="bucket_suffix=<unique>"
terraform apply -var-file=example.tfvars.example -var="bucket_suffix=<unique>"
```

See [`environments/example/README.md`](environments/example/README.md) for the full
wiring diagram and a cost warning (NAT gateway + RDS are the main charges).

## Continuous integration

`.github/workflows/terraform-ci.yml` runs on every pull request and on push to
`main`:

| Job        | What it does                                                        |
|------------|---------------------------------------------------------------------|
| `fmt`      | `terraform fmt -check -recursive`                                    |
| `validate` | `terraform init -backend=false` + `validate` for each module and the example |
| `test`     | `terraform test` per module — plan-based, with a mocked AWS provider (no credentials, nothing created) |
| `lint`     | `tflint` (terraform + AWS rulesets, see `.tflint.hcl`)               |
| `security` | `tfsec`, failing only on **high/critical** findings                 |
| `secrets`  | `gitleaks` secret scan                                              |
| `plan`     | smoke `terraform plan` of `environments/example` (PRs only), posted as a PR comment |

`fmt`/`validate`/`test`/`lint`/`security`/`secrets` gate merges. The `plan` job runs
only when the OIDC role is configured (see below), so CI still works without AWS
access.

### Tests

Each module has plan-based tests under `modules/<name>/tests/*.tftest.hcl`, run with
`terraform test`. They use `mock_provider "aws"`, so they execute in seconds without
AWS credentials and create nothing — they assert on the plan (secure defaults, naming,
conditional resources) and on expected validation/precondition failures. Run them
locally with:

```bash
cd modules/vpc && terraform init -backend=false && terraform test
```

Deploy-and-destroy integration tests (e.g. Terratest) against a real account are a
possible future addition; they are deliberately out of scope here since this repo is a
reference/base and incurs cost only when actually applied.

### AWS authentication (OIDC, no static keys)

The `plan` and `apply` jobs obtain short-lived AWS credentials via GitHub OIDC —
there are **no** `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` secrets. To enable them,
configure in the repository:

- **Variables**: `AWS_ROLE_TO_ASSUME` (IAM role ARN), `AWS_REGION`, and
  `TF_BUCKET_SUFFIX` (for apply).
- **Secret**: `TF_VAR_DB_PASSWORD` (for apply).

Create the role once (out of band, or via a small `bootstrap/` you add later): an IAM
OIDC identity provider for `token.actions.githubusercontent.com`, and an IAM role
whose trust policy is scoped to this repository (`sub` = `repo:<owner>/<repo>:*`) with
the permissions Terraform needs. See the AWS/GitHub OIDC documentation for the exact
trust policy.

### Apply (manual, approval-gated)

`.github/workflows/terraform-apply.yml` is a manual `workflow_dispatch` that requires
typing `apply` to confirm and runs in a protected `production` environment (configure
required reviewers on it). It runs `terraform apply` with the same OIDC role and
**creates billable resources** — use deliberately and `destroy` afterwards.

## Status

All modules are implemented (`vpc`, `iam`, `s3`, `rds`, `ec2`, `alb`, `route53`),
composed in `environments/example` (internet → ALB → private ASG → RDS/S3), covered
by plan-based `terraform test` per module, and gated by CI (fmt, validate, test, lint,
security, secret scan, plan) plus a manual, approval-gated apply workflow.

## License

MIT
