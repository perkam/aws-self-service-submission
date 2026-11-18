variable "name" {
  description = "Name of the load balancer, also used for its security group."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create the load balancer in."
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets for the load balancer, in at least two AZs."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "public_subnet_ids must contain at least two subnets."
  }
}

variable "ingress_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the load balancer on port 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_deletion_protection" {
  description = "Whether to prevent the load balancer from being deleted."
  type        = bool
  default     = false
}
