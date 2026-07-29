locals {
  name_prefix   = "${var.project}-${var.environment}"
  https_enabled = var.acm_certificate_arn != ""

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# ALB security group. An internet-facing load balancer is meant to receive public
# traffic, so ingress from the configured CIDRs (0.0.0.0/0 by default) on the
# listener ports is intentional. Egress is open so the ALB can reach the backend
# instances; keeping it open (rather than referencing the app security group)
# avoids a dependency cycle between the two security groups.
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Load balancer for ${local.name_prefix}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# tfsec:ignore:aws-ec2-no-public-ingress-sgr Public ingress is expected for an internet-facing ALB.
resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = var.listener_port
  to_port           = var.listener_port
  ip_protocol       = "tcp"
  description       = "HTTP from ${each.value}"
}

# tfsec:ignore:aws-ec2-no-public-ingress-sgr Public ingress is expected for an internet-facing ALB.
resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = local.https_enabled ? toset(var.ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic to targets"
}

# This module's purpose is an internet-facing ALB; being public is intentional.
# Set internal = true for an internal load balancer.
# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "this" {
  name_prefix        = substr(replace("${var.project}${var.environment}", "-", ""), 0, 6)
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "this" {
  name_prefix = "tg-"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP listener: forwards to the target group, or redirects to HTTPS when a
# certificate is configured.
# tfsec:ignore:aws-elb-http-not-used Plain HTTP is the default for the fictitious .example domain (no ACM cert); set acm_certificate_arn to enable HTTPS and redirect.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.https_enabled ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.https_enabled ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
