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

  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023[0].id
}

# Look up the latest Amazon Linux 2023 AMI only when the caller does not pin one.
data "aws_ami" "al2023" {
  count = var.ami_id == "" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance security group. Ingress on app_port comes only from the load balancer
# security group (if provided) or from the given CIDRs (e.g. the VPC CIDR) —
# never from 0.0.0.0/0. Egress is open so instances can reach updates, S3 and RDS
# through the NAT gateway.
resource "aws_security_group" "ec2" {
  name_prefix = "${local.name_prefix}-ec2-"
  description = "Application instances for ${local.name_prefix}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.alb_security_group_id != "" || length(var.ingress_cidr_blocks) > 0
      error_message = "Provide alb_security_group_id or a non-empty ingress_cidr_blocks so the application port has a defined, non-public source."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  count = var.alb_security_group_id != "" ? 1 : 0

  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "Application traffic from the load balancer"
}

resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each = var.alb_security_group_id == "" ? toset(var.ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = each.value
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
  description       = "Application traffic from ${each.value}"
}

# Open egress is intentional: private instances need outbound access (via NAT) for
# package updates and to reach S3/RDS. Ingress remains locked down above.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

resource "aws_launch_template" "this" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  user_data     = var.user_data != "" ? base64encode(var.user_data) : null

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Require IMDSv2 (token-based instance metadata).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-ec2"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-ec2-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lt"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix         = "${local.name_prefix}-asg-"
  vpc_zone_identifier = var.subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = var.health_check_type
  health_check_grace_period = 300
  target_group_arns         = var.target_group_arns

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "${local.name_prefix}-ec2" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
