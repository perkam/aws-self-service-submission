resource "aws_security_group" "service" {
  name        = "${var.name}-service"
  description = "Controls traffic to and from the ${var.name} service."
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-service"
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  security_group_id            = aws_security_group.service.id
  description                  = "Application traffic from the load balancer"
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

# Tasks reach ECR, S3 and CloudWatch Logs over HTTPS through the NAT gateway.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.service.id
  description       = "HTTPS to AWS APIs and the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_service" {
  security_group_id            = var.alb_security_group_id
  description                  = "Application traffic to the ${var.name} service"
  referenced_security_group_id = aws_security_group.service.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}
