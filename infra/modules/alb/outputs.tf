output "dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Route 53 zone ID of the load balancer, used for alias records."
  value       = aws_lb.this.zone_id
}

output "listener_arn" {
  description = "ARN of the listener that services attach their rules to."
  value       = aws_lb_listener.http.arn
}

output "security_group_id" {
  description = "ID of the load balancer's security group."
  value       = aws_security_group.this.id
}
