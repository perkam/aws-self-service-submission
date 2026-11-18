variable "name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "container_insights" {
  description = "Container Insights mode: disabled, enabled or enhanced."
  type        = string
  default     = "enhanced"

  validation {
    condition     = contains(["disabled", "enabled", "enhanced"], var.container_insights)
    error_message = "container_insights must be disabled, enabled or enhanced."
  }
}
