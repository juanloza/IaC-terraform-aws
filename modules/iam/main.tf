data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  # Scope CloudWatch Logs permissions to a specific log group. When the caller
  # does not pass an ARN, default to log groups under "/<project>/<environment>/"
  # in the current account and region instead of falling back to "*".
  log_group_arn = var.cloudwatch_log_group_arn != "" ? var.cloudwatch_log_group_arn : "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/${var.project}/${var.environment}/*"
}

# Trust policy: only the EC2 service may assume this role.
data "aws_iam_policy_document" "assume" {
  statement {
    sid     = "AllowEc2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-role"
  })
}

# Least-privilege permissions: object read/write and listing on the project
# bucket only, plus writing to the project's CloudWatch log group. No wildcards
# on resources, no IAM/administration actions.
data "aws_iam_policy_document" "ec2" {
  statement {
    sid       = "S3BucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.s3_bucket_arn]
  }

  statement {
    sid       = "S3ObjectReadWrite"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${var.s3_bucket_arn}/*"]
  }

  statement {
    sid     = "CloudWatchLogsWrite"
    effect  = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      local.log_group_arn,
      "${local.log_group_arn}:*",
    ]
  }
}

resource "aws_iam_policy" "ec2" {
  name        = "${local.name_prefix}-ec2-policy"
  description = "Least-privilege access for ${local.name_prefix} EC2 instances (project S3 bucket + CloudWatch Logs)."
  policy      = data.aws_iam_policy_document.ec2.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-profile"
  })
}
