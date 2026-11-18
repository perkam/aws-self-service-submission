variable "name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "images_to_keep" {
  description = "Number of most recent images to keep in the repository."
  type        = number
  default     = 20

  validation {
    condition     = var.images_to_keep >= 1 && floor(var.images_to_keep) == var.images_to_keep
    error_message = "images_to_keep must be a whole number of at least 1."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to push images, in owner/name format."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in owner/name format."
  }
}

variable "github_oidc_provider_arn" {
  description = "ARN of the account's GitHub OIDC provider."
  type        = string
}
