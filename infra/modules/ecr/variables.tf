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
