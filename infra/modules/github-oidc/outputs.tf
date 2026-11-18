output "provider_arn" {
  description = "ARN of the GitHub OIDC provider, used in the trust policies of CI roles."
  value       = aws_iam_openid_connect_provider.github.arn
}
