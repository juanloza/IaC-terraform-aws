# alb

Internet-facing Application Load Balancer for the `acme-app` stack. It fronts the
private EC2 Auto Scaling Group: public traffic hits the ALB in the public subnets,
which forwards to the instances in the private subnets. It is the entry point the
`route53` module aliases to.

## What it configures

- **Security group** that accepts the listener ports (80, and 443 when HTTPS is
  enabled) from `ingress_cidr_blocks` (the whole internet by default — expected for a
  public ALB). Egress is open so the ALB can reach the targets.
- **Application Load Balancer** with `drop_invalid_header_fields = true`, optional
  deletion protection and a configurable idle timeout.
- **Target group** (HTTP, `app_port`, `target_type = instance`) with an HTTP health
  check. Attach the ASG to it via the `ec2` module's `target_group_arns`.
- **Listeners**: an HTTP listener that forwards to the target group; if
  `acm_certificate_arn` is set, the HTTP listener instead redirects to an HTTPS:443
  listener that terminates TLS.

## HTTP vs HTTPS

The example environment uses the fictitious `acme-app.example` domain, which ACM
cannot validate, so the default is an **HTTP-only** ALB. For real use, request an ACM
certificate for a domain you own and pass `acm_certificate_arn`: the module then adds
the HTTPS listener and redirects HTTP → HTTPS automatically.

## Avoiding a security-group cycle

The ALB egress is left open rather than referencing the app security group. The `ec2`
module allows ingress **from the ALB security group**; if the ALB also referenced the
app SG, the two modules would depend on each other. Open egress on the ALB breaks that
cycle while ingress to the instances stays locked to the ALB.

## Usage

```hcl
module "alb" {
  source = "../../modules/alb"

  project     = "acme-app"
  environment = "example"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  app_port          = 8080
  health_check_path = "/health"
  # acm_certificate_arn = module.acm.certificate_arn  # enables HTTPS + redirect
}

# Wire it to the compute and DNS:
#   ec2:     alb_security_group_id = module.alb.security_group_id
#            target_group_arns     = [module.alb.target_group_arn]
#            health_check_type     = "ELB"
#   route53: target_dns_name = module.alb.alb_dns_name
#            target_zone_id  = module.alb.alb_zone_id
```

A runnable example lives in [`examples/basic`](./examples/basic).

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.7  |
| aws       | ~> 5.0  |

## Inputs

| Name                         | Type           | Default                              | Required | Description                                                        |
|------------------------------|----------------|--------------------------------------|:--------:|--------------------------------------------------------------------|
| `project`                    | `string`       | n/a                                  |   yes    | Project name, used for naming and tagging.                         |
| `environment`                | `string`       | n/a                                  |   yes    | Environment name.                                                  |
| `vpc_id`                     | `string`       | n/a                                  |   yes    | VPC for the ALB, target group and SG.                             |
| `subnet_ids`                 | `list(string)` | n/a                                  |   yes    | Subnets for the ALB (public for internet-facing; ≥ 2 AZs).        |
| `internal`                   | `bool`         | `false`                              |    no    | Make the ALB internal (no public IP).                             |
| `listener_port`              | `number`       | `80`                                 |    no    | HTTP listener port.                                               |
| `app_port`                   | `number`       | `8080`                               |    no    | Target group / backend port (match the ec2 module).               |
| `ingress_cidr_blocks`        | `list(string)` | `["0.0.0.0/0"]`                      |    no    | CIDRs allowed to reach the listeners.                             |
| `health_check_path`          | `string`       | `"/"`                                |    no    | Health check path.                                                |
| `health_check_matcher`       | `string`       | `"200"`                              |    no    | Healthy HTTP status code(s).                                      |
| `acm_certificate_arn`        | `string`       | `""`                                 |    no    | ACM cert ARN; enables HTTPS + HTTP→HTTPS redirect.               |
| `ssl_policy`                 | `string`       | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no    | SSL policy for the HTTPS listener.                                |
| `enable_deletion_protection` | `bool`         | `false`                              |    no    | Prevent ALB deletion (enable in production).                      |
| `idle_timeout`               | `number`       | `60`                                 |    no    | Connection idle timeout (seconds).                                |
| `tags`                       | `map(string)`  | `{}`                                 |    no    | Extra tags merged onto every resource.                            |

## Outputs

| Name                 | Description                                                    |
|----------------------|----------------------------------------------------------------|
| `alb_arn`            | Load balancer ARN.                                            |
| `alb_dns_name`       | ALB DNS name (Route 53 alias `target_dns_name`).             |
| `alb_zone_id`        | ALB hosted zone ID (Route 53 alias `target_zone_id`).       |
| `security_group_id`  | ALB security group ID (ec2 `alb_security_group_id`).        |
| `target_group_arn`   | Target group ARN (ec2 `target_group_arns`).                 |
| `http_listener_arn`  | HTTP listener ARN.                                           |
| `https_listener_arn` | HTTPS listener ARN, or `null` when HTTPS is disabled.       |
