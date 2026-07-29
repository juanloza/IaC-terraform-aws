# ec2

Application compute for the `acme-app` stack: an Auto Scaling Group of EC2
instances in the **private** subnets, built from a launch template that carries the
IAM instance profile, requires IMDSv2, and uses an encrypted root volume.

## What it configures

- **Security group** whose ingress on `app_port` is restricted to either a load
  balancer security group (`alb_security_group_id`) or a set of CIDRs
  (`ingress_cidr_blocks`, e.g. the VPC CIDR) — **never `0.0.0.0/0`** (enforced by a
  variable validation). Egress is open so instances can reach updates, S3 and RDS
  through the NAT gateway.
- **Launch template**: AMI, instance type, the IAM instance profile from the `iam`
  module, optional `user_data`, IMDSv2 required, and an encrypted `gp3` root volume.
- **Auto Scaling Group** across the private subnets with configurable
  `min`/`max`/`desired` sizes, optionally attached to `target_group_arns` for a load
  balancer added later.

## AMI selection

Leave `ami_id` empty (the default) and the module resolves the latest Amazon Linux
2023 x86_64 AMI via a `data "aws_ami"` lookup (owner `amazon`,
`al2023-ami-2023.*-x86_64`). Pin a specific `ami_id` for reproducible builds. No AMI
ID is hard-coded in the module.

## Load balancer scope

An ALB is intentionally out of scope for this module. The security group and ASG are
shaped to integrate with one later without structural changes: pass
`alb_security_group_id` to source ingress from the ALB, set `health_check_type = "ELB"`,
and provide `target_group_arns`.

## Design notes

- Instances live only in the private subnets passed via `subnet_ids`; there is no
  public IP path to them.
- Keep application logic out of the module — pass a boot script through `user_data`.
- The module declares no `provider` block; it inherits the AWS provider (and region)
  from the calling root module.

## Usage

```hcl
module "ec2" {
  source = "../../modules/ec2"

  project     = "acme-app"
  environment = "example"

  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  iam_instance_profile = module.iam.ec2_instance_profile_name

  instance_type       = "t3.micro"
  app_port            = 8080
  ingress_cidr_blocks = [module.vpc.vpc_cidr] # or set alb_security_group_id

  min_size         = 1
  max_size         = 3
  desired_capacity = 2
}

# Feed the security group into the rds module:
#   allowed_security_group_id = module.ec2.security_group_id
```

A runnable example lives in [`examples/basic`](./examples/basic).

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.7  |
| aws       | ~> 5.0  |

## Inputs

| Name                    | Type           | Default        | Required | Description                                                             |
|-------------------------|----------------|----------------|:--------:|-------------------------------------------------------------------------|
| `project`               | `string`       | n/a            |   yes    | Project name, used for naming and tagging.                              |
| `environment`           | `string`       | n/a            |   yes    | Environment name.                                                       |
| `vpc_id`                | `string`       | n/a            |   yes    | VPC for the instance security group.                                    |
| `subnet_ids`            | `list(string)` | n/a            |   yes    | Private subnet IDs for the ASG.                                         |
| `iam_instance_profile`  | `string`       | n/a            |   yes    | Instance profile name (from the `iam` module).                          |
| `ami_id`                | `string`       | `""`           |    no    | AMI ID; empty looks up the latest Amazon Linux 2023.                    |
| `instance_type`         | `string`       | `"t3.micro"`   |    no    | Instance type.                                                          |
| `root_volume_size`      | `number`       | `20`           |    no    | Root EBS volume size (GB).                                              |
| `user_data`             | `string`       | `""`           |    no    | Boot script (plain text; base64-encoded by the module).                |
| `min_size`              | `number`       | `1`            |    no    | ASG minimum size.                                                       |
| `max_size`              | `number`       | `2`            |    no    | ASG maximum size.                                                       |
| `desired_capacity`      | `number`       | `1`            |    no    | ASG desired capacity.                                                   |
| `app_port`              | `number`       | `8080`         |    no    | Application port for the ingress rule.                                  |
| `alb_security_group_id` | `string`       | `""`           |    no    | Source SG for ingress; takes precedence over `ingress_cidr_blocks`.     |
| `ingress_cidr_blocks`   | `list(string)` | `[]`           |    no    | CIDRs allowed on `app_port` (no `0.0.0.0/0`); used when no ALB SG.      |
| `target_group_arns`     | `list(string)` | `[]`           |    no    | Target group ARNs to attach the ASG to.                                |
| `health_check_type`     | `string`       | `"EC2"`        |    no    | `EC2` or `ELB`.                                                         |
| `tags`                  | `map(string)`  | `{}`           |    no    | Extra tags merged onto every resource.                                 |

## Outputs

| Name                             | Description                                              |
|----------------------------------|----------------------------------------------------------|
| `autoscaling_group_name`         | ASG name.                                                |
| `autoscaling_group_arn`          | ASG ARN.                                                 |
| `security_group_id`              | Instance SG ID (pass to `rds` as `allowed_security_group_id`). |
| `launch_template_id`             | Launch template ID.                                      |
| `launch_template_latest_version` | Latest launch template version.                          |
