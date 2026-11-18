resource "aws_lb_target_group" "this" {
  name                 = var.name
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check.path
    matcher             = var.health_check.matcher
    interval            = var.health_check.interval
    timeout             = var.health_check.timeout
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.alb_listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  dynamic "condition" {
    for_each = length(var.path_patterns) > 0 ? [var.path_patterns] : []

    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = length(var.host_headers) > 0 ? [var.host_headers] : []

    content {
      host_header {
        values = condition.value
      }
    }
  }
}
