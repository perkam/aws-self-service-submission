output "service_name" {
  description = "Name of the ECS service, used for alarms and autoscaling."
  value       = aws_ecs_service.this.name
}

output "security_group_id" {
  description = "ID of the service's security group."
  value       = aws_security_group.service.id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group holding the service's logs."
  value       = aws_cloudwatch_log_group.this.name
}
