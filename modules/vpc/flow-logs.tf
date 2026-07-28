# Optional VPC flow logs, delivered to CloudWatch Logs through a dedicated
# least-privilege IAM role. Everything here is created only when
# enable_flow_logs is true.

locals {
  flow_logs_count = var.enable_flow_logs ? 1 : 0
}

resource "aws_cloudwatch_log_group" "flow" {
  count = local.flow_logs_count

  name              = "/aws/vpc-flow-logs/${local.name_prefix}"
  retention_in_days = var.flow_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-flow-logs"
  })
}

data "aws_iam_policy_document" "flow_assume" {
  count = local.flow_logs_count

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow" {
  count = local.flow_logs_count

  name               = "${local.name_prefix}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_assume[0].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-flow-logs-role"
  })
}

# Permissions are scoped to this VPC's flow log group only; no wildcards on
# resources beyond the log streams within that group.
data "aws_iam_policy_document" "flow_permissions" {
  count = local.flow_logs_count

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      aws_cloudwatch_log_group.flow[0].arn,
      "${aws_cloudwatch_log_group.flow[0].arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "flow" {
  count = local.flow_logs_count

  name   = "${local.name_prefix}-flow-logs-policy"
  role   = aws_iam_role.flow[0].id
  policy = data.aws_iam_policy_document.flow_permissions[0].json
}

resource "aws_flow_log" "this" {
  count = local.flow_logs_count

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow[0].arn
  iam_role_arn             = aws_iam_role.flow[0].arn
  max_aggregation_interval = 600

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-flow-log"
  })
}
