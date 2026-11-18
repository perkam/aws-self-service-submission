variable "name" {
  description = "Name of the HTTP service, also used for its related resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,30}[a-zA-Z0-9])?$", var.name))
    error_message = "name must be 1-32 letters, numbers or hyphens, and can't start or end with a hyphen, because target group names have this limit."
  }
}

variable "image" {
  description = "Full container image reference, including its tag."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
}

variable "environment" {
  description = "Plain environment variables for the container. Don't put secrets here."
  type        = map(string)
  default     = {}
}

variable "cpu" {
  description = "CPU units for the task, where 1024 is one vCPU."
  type        = number

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.cpu)
    error_message = "cpu must be a value supported by Fargate: 256, 512, 1024, 2048, 4096, 8192 or 16384."
  }
}

variable "memory" {
  description = "Memory for the task in MiB. The allowed values depend on cpu."
  type        = number
}

variable "desired_count" {
  description = "Number of tasks to keep running."
  type        = number

  validation {
    condition     = var.desired_count >= 0 && floor(var.desired_count) == var.desired_count
    error_message = "desired_count must be a whole number of at least 0."
  }
}

variable "log_retention_days" {
  description = "Number of days to keep the service's logs."
  type        = number

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "keep_logs_on_destroy" {
  description = "Whether to keep the log group in AWS when the service is destroyed."
  type        = bool
  default     = false
}

variable "health_check" {
  description = "Load balancer health check settings."
  type = object({
    path                = string
    matcher             = optional(string, "200")
    interval            = optional(number, 30)
    timeout             = optional(number, 5)
    healthy_threshold   = optional(number, 2)
    unhealthy_threshold = optional(number, 3)
  })
}

variable "deregistration_delay" {
  description = "Seconds to let in-flight requests finish before a task is removed."
  type        = number
  default     = 30
}

variable "health_check_grace_period" {
  description = "Seconds to ignore failed health checks after a task starts."
  type        = number
  default     = 30
}

variable "path_patterns" {
  description = "URL paths routed to this service, such as /orders/*."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.path_patterns) > 0 || length(var.host_headers) > 0
    error_message = "At least one of path_patterns or host_headers must be set."
  }
}

variable "host_headers" {
  description = "Host names routed to this service, such as orders.example.com."
  type        = list(string)
  default     = []
}

variable "listener_rule_priority" {
  description = "Optional rule priority. Leave unset to let AWS assign the next one."
  type        = number
  default     = null

  validation {
    condition = var.listener_rule_priority == null || (
      var.listener_rule_priority >= 1 &&
      var.listener_rule_priority <= 50000 &&
      floor(var.listener_rule_priority) == var.listener_rule_priority
    )
    error_message = "listener_rule_priority must be a whole number between 1 and 50000."
  }
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster to run the service in."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to run the service in."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for the service's tasks."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 1
    error_message = "private_subnet_ids must contain at least one subnet."
  }
}

variable "alb_listener_arn" {
  description = "ARN of the load balancer listener to add the routing rule to."
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the load balancer's security group."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the service pulls its image from."
  type        = string
}
