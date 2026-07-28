# vpc

Base network for the `acme-app` reference stack: a VPC with public and private
subnets spread across one or more availability zones, an internet gateway for the
public subnets, and NAT gateway(s) giving the private subnets outbound-only
internet access. Every other module in this collection (EC2, RDS, ...) is placed
into the subnets this module creates.

## Design notes

- Subnets iterate over `azs` with `count`, so `azs`, `public_subnet_cidrs` and
  `private_subnet_cidrs` must all have the same length (enforced by variable
  validation). At least two AZs are recommended for high availability.
- `public_subnet_ids` and `private_subnet_ids` are plain lists ordered to match
  `azs`, so they can be passed straight into the `ec2` and `rds` modules.
- The module declares no `provider` block; it inherits the AWS provider (and
  therefore the region) from the root module that calls it.
- VPC flow logs are captured to CloudWatch Logs by default (`enable_flow_logs`),
  delivered through a dedicated IAM role scoped to just this VPC's log group.

## Cost warning

NAT gateways are **not free**: each one bills per hour plus per GB of processed
traffic, independent of whether the private instances send much data. Elastic IPs
attached to them also bill while allocated. `single_nat_gateway = true` (the
default) keeps this to one NAT gateway to minimise cost; set it to `false` only
when you need per-AZ resilience and accept the higher bill. Run `terraform destroy`
on any environment you are not actively using.

VPC flow logs (`enable_flow_logs = true` by default) also incur CloudWatch Logs
ingestion and storage cost. Set `enable_flow_logs = false` to disable them, or
tune `flow_log_retention_days` to cap storage.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project     = "acme-app"
  environment = "example"

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  single_nat_gateway   = true

  tags = {
    Owner = "platform"
  }
}
```

A runnable example lives in [`examples/basic`](./examples/basic).

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.7  |
| aws       | ~> 5.0  |

## Inputs

| Name                   | Type           | Default | Required | Description                                                                 |
|------------------------|----------------|---------|:--------:|-----------------------------------------------------------------------------|
| `project`              | `string`       | n/a     |   yes    | Project name, used for naming and tagging.                                  |
| `environment`          | `string`       | n/a     |   yes    | Environment name (e.g. `example`, `staging`, `prod`).                       |
| `vpc_cidr`             | `string`       | n/a     |   yes    | CIDR block for the VPC.                                                      |
| `azs`                  | `list(string)` | n/a     |   yes    | Availability zones to spread subnets across.                                |
| `public_subnet_cidrs`  | `list(string)` | n/a     |   yes    | One CIDR per AZ for the public subnets (same length as `azs`).              |
| `private_subnet_cidrs` | `list(string)` | n/a     |   yes    | One CIDR per AZ for the private subnets (same length as `azs`).             |
| `single_nat_gateway`   | `bool`         | `true`  |    no    | One shared NAT gateway (`true`) or one per AZ (`false`).                     |
| `enable_flow_logs`     | `bool`         | `true`  |    no    | Capture VPC flow logs to CloudWatch via a dedicated IAM role.               |
| `flow_log_retention_days` | `number`    | `30`    |    no    | Retention for the flow logs log group (used only when flow logs are on).    |
| `tags`                 | `map(string)`  | `{}`    |    no    | Extra tags merged onto every resource.                                      |

## Outputs

| Name                 | Description                                                     |
|----------------------|-----------------------------------------------------------------|
| `vpc_id`             | ID of the VPC.                                                   |
| `vpc_cidr`           | CIDR block of the VPC.                                           |
| `public_subnet_ids`  | Public subnet IDs, ordered to match `azs`.                      |
| `private_subnet_ids` | Private subnet IDs, ordered to match `azs`.                    |
| `nat_gateway_ids`    | NAT gateway IDs (one, or one per AZ when `single_nat_gateway=false`). |
| `flow_log_group_name`| CloudWatch log group name for flow logs, or `null` when disabled. |
