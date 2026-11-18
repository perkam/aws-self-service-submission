# Has no egress rules here: each service adds a rule allowing the load balancer
# to reach its own port.
resource "aws_security_group" "this" {
  name        = "${var.name}-alb"
  description = "Controls traffic to and from the ${var.name} load balancer."
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  #checkov:skip=CKV_AWS_260:The load balancer is the public entry point, and access can be limited with ingress_cidrs.
  for_each = toset(var.ingress_cidrs)

  security_group_id = aws_security_group.this.id
  description       = "HTTP from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_150:Set per environment with enable_deletion_protection, so dev can be destroyed.
  #checkov:skip=CKV_AWS_91:Access logs are deferred to the production hardening work.
  #checkov:skip=CKV2_AWS_20:HTTPS is deferred until a domain is delegated to this environment.
  #checkov:skip=CKV2_AWS_28:AWS WAF is deferred to the production hardening work.
  name                       = var.name
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.this.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = var.enable_deletion_protection
}

# Services add their own listener rules. Requests matching none of them get a 404.
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:HTTPS is deferred until a domain is delegated to this environment.
  #checkov:skip=CKV_AWS_103:TLS is deferred until a domain is delegated to this environment.
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}
