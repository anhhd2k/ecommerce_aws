###############################################################################
# Internal Application Load Balancer
#
# Fronts the four backend microservices (product, cart, user, order) running in
# the private application tier. Internal-only: no public IPs, reachable from
# within the VPC. Path-based listener rules route to per-service target groups
# (IP target type, one port per service 8001-8004).
#
# Service URLs are published to SSM Parameter Store so other components can
# discover the ALB endpoint.
###############################################################################

locals {
  # Per-service configuration driving target groups, listener rules and SSM.
  alb_services = {
    product = {
      port         = 8001
      path_pattern = "/products*"
      priority     = 10
    }
    cart = {
      port         = 8002
      path_pattern = "/cart*"
      priority     = 20
    }
    user = {
      port         = 8003
      path_pattern = "/user*"
      priority     = 30
    }
    order = {
      port         = 8004
      path_pattern = "/order*"
      priority     = 40
    }
  }
}

###############################################################################
# Security group: ALB - allow HTTP from the VPC CIDR
###############################################################################

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Internal ALB - allow HTTP from within the VPC."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  description       = "HTTP from the VPC CIDR."
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  description       = "Allow all outbound (to backend targets)."
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

###############################################################################
# Target groups (one per service, IP target type, health check on /health)
###############################################################################

resource "aws_lb_target_group" "services" {
  for_each = local.alb_services

  name        = "${local.name_prefix}-${each.key}-tg"
  port        = each.value.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name    = "${local.name_prefix}-${each.key}-tg"
    Service = each.key
  }
}

###############################################################################
# Application Load Balancer (internal)
###############################################################################

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.app[*].id

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

###############################################################################
# Listener (HTTP :80) + path-based routing rules
###############################################################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action: 404 for unmatched paths.
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "services" {
  for_each = local.alb_services

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }

  tags = {
    Name    = "${local.name_prefix}-${each.key}-rule"
    Service = each.key
  }
}

###############################################################################
# SSM Parameter Store: per-service URLs pointing at the internal ALB DNS
#   /ecommerce/dev/product-service-url -> http://<alb-dns>
###############################################################################

resource "aws_ssm_parameter" "service_url" {
  for_each = local.alb_services

  name        = "/${var.project}/${var.environment}/${each.key}-service-url"
  description = "Internal ALB URL for the ${each.key} service."
  type        = "String"
  value       = "http://${aws_lb.main.dns_name}"

  tags = {
    Name    = "${local.name_prefix}-${each.key}-service-url"
    Service = each.key
  }
}
