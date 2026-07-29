# route53

DNS for the `acme-app` stack: a hosted zone (created here or looked up if it
already exists) plus an A/ALIAS record pointing at the application entry point and
any CNAME records you need.

> **Fictitious domain.** The repository examples use `acme-app.example`. The
> `.example` TLD is reserved for documentation (RFC 2606) and can never resolve on
> the public internet, so nothing here touches a real domain. To actually apply
> this, pass a `domain_name` you own — never a third party's domain.

## What it configures

- **Hosted zone**: created when `create_zone = true` (default), or resolved from an
  existing zone by name via a data source when `create_zone = false`. Either way the
  module exposes the same `zone_id` and `name_servers` outputs, so it behaves
  identically to callers.
- **A/ALIAS record**: points the apex (or the `alias_record_name` subdomain) at
  `target_dns_name` / `target_zone_id` — typically a load balancer. Created only
  when both target values are supplied.
- **CNAME records**: from the `cname_records` map, e.g. `{ www = "acme-app.example" }`.

## Design notes

- When the zone is created, set the returned `name_servers` at your domain registrar
  so the zone becomes authoritative — Terraform cannot do this for you.
- The module declares no `provider` block; it inherits the AWS provider from the
  calling root module.

## Usage

```hcl
module "route53" {
  source = "../../modules/route53"

  project     = "acme-app"
  environment = "example"

  domain_name = "acme-app.example" # a domain you own
  create_zone = true

  # Point the apex at a load balancer:
  target_dns_name = module.alb.dns_name
  target_zone_id  = module.alb.zone_id

  cname_records = {
    www = "acme-app.example"
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

| Name                     | Type          | Default | Required | Description                                                                |
|--------------------------|---------------|---------|:--------:|----------------------------------------------------------------------------|
| `project`                | `string`      | n/a     |   yes    | Project name, used for tagging.                                            |
| `environment`            | `string`      | n/a     |   yes    | Environment name.                                                          |
| `domain_name`            | `string`      | n/a     |   yes    | Hosted zone domain name (a domain you own).                               |
| `create_zone`            | `bool`        | `true`  |    no    | Create the zone (`true`) or look up an existing one (`false`).            |
| `create_alias_record`    | `bool`        | `true`  |    no    | Create the apex A/ALIAS record (needs the target values).                 |
| `alias_record_name`      | `string`      | `""`    |    no    | Subdomain for the alias; empty means the zone apex.                       |
| `target_dns_name`        | `string`      | `""`    |    no    | DNS name of the alias target (e.g. the load balancer).                    |
| `target_zone_id`         | `string`      | `""`    |    no    | Hosted zone ID of the alias target.                                       |
| `evaluate_target_health` | `bool`        | `true`  |    no    | Whether the alias evaluates target health.                               |
| `cname_records`          | `map(string)` | `{}`    |    no    | CNAME records as `subdomain => target`.                                    |
| `cname_ttl`              | `number`      | `300`   |    no    | TTL for CNAME records.                                                     |
| `tags`                   | `map(string)` | `{}`    |    no    | Extra tags merged onto the hosted zone (when created).                    |

## Outputs

| Name                | Description                                                        |
|---------------------|--------------------------------------------------------------------|
| `zone_id`           | Hosted zone ID (created or looked up).                             |
| `zone_name`         | Hosted zone domain name.                                           |
| `name_servers`      | Name servers to set at the registrar (when the zone is created).  |
| `alias_record_fqdn` | FQDN of the alias record, or `null` when none was created.        |
