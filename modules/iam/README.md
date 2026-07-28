# iam

Least-privilege IAM for the `acme-app` application compute. It creates the IAM
role, policy and instance profile that EC2 instances assume to reach exactly the
resources they need — the project's S3 bucket and its CloudWatch log group — and
nothing else.

## What it grants

The attached policy is scoped, with no `Resource: "*"` and no administration or
IAM actions:

| Statement            | Actions                              | Resource                          |
|----------------------|--------------------------------------|-----------------------------------|
| `S3BucketList`       | `s3:ListBucket`                      | the project bucket ARN            |
| `S3ObjectReadWrite`  | `s3:GetObject`, `s3:PutObject`       | objects in the bucket (`<arn>/*`) |
| `CloudWatchLogsWrite`| `logs:CreateLogStream`, `logs:PutLogEvents` | the project log group (`<arn>` and `<arn>:*`) |

`s3:ListBucket` is a bucket-level action, so it targets the bucket ARN; the object
actions target `<bucket_arn>/*`. That split is what keeps the grant to just this
bucket.

## Design notes

- **No static credentials**: access is delivered through an instance profile
  (temporary STS credentials), so there are no IAM users or long-lived access keys.
- **CloudWatch Logs scoping**: pass `cloudwatch_log_group_arn` to target a specific
  log group. If omitted, permissions are scoped to log groups matching
  `/<project>/<environment>/*` in the current account and region (derived via
  `aws_caller_identity` / `aws_region` / `aws_partition`) rather than `*`.
- The module declares no `provider` block; it inherits the AWS provider (and region)
  from the calling root module.

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  project     = "acme-app"
  environment = "example"

  s3_bucket_arn = module.s3.bucket_arn
  # cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/acme-app/example/app"
}

# Then hand the profile to the ec2 module:
#   iam_instance_profile = module.iam.ec2_instance_profile_name
```

A runnable example lives in [`examples/basic`](./examples/basic).

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.7  |
| aws       | ~> 5.0  |

## Inputs

| Name                       | Type          | Default | Required | Description                                                                 |
|----------------------------|---------------|---------|:--------:|-----------------------------------------------------------------------------|
| `project`                  | `string`      | n/a     |   yes    | Project name, used for naming and tagging.                                  |
| `environment`              | `string`      | n/a     |   yes    | Environment name (e.g. `example`, `staging`, `prod`).                       |
| `s3_bucket_arn`            | `string`      | n/a     |   yes    | ARN of the bucket the role may access (from the `s3` module).               |
| `cloudwatch_log_group_arn` | `string`      | `""`    |    no    | Specific log group ARN; empty scopes to `/<project>/<environment>/*`.       |
| `tags`                     | `map(string)` | `{}`    |    no    | Extra tags merged onto every resource.                                      |

## Outputs

| Name                         | Description                                              |
|------------------------------|----------------------------------------------------------|
| `ec2_instance_profile_name`  | Instance profile name to pass to the `ec2` module.       |
| `ec2_instance_profile_arn`   | Instance profile ARN.                                    |
| `ec2_role_arn`               | EC2 IAM role ARN.                                        |
| `ec2_role_name`              | EC2 IAM role name.                                       |
| `ec2_policy_arn`             | ARN of the least-privilege policy attached to the role.  |
