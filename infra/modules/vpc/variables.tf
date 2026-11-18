variable "name" {
  description = "Name used for the Name tag of the VPC and its subnets, e.g. dev."
  type        = string
}

variable "cidr" {
  description = "CIDR block of the VPC, e.g. 10.10.0.0/16."
  type        = string
}

variable "azs" {
  description = "Availability zones to create subnets in, e.g. [\"eu-north-1a\", \"eu-north-1b\"]. Subnets are assigned to AZs by list index."
  type        = list(string)
  validation {
    condition     = length(distinct(var.azs)) == length(var.azs)
    error_message = "azs must not contain duplicates."
  }
}

variable "public_subnets" {
  description = "CIDR blocks of the public subnets, one per AZ (same order as azs)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) == length(var.azs)
    error_message = "public_subnets must have exactly one CIDR per AZ in azs."
  }
}

variable "private_subnets" {
  description = "CIDR blocks of the private subnets, one per AZ (same order as azs)."
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) == length(var.azs)
    error_message = "private_subnets must have exactly one CIDR per AZ in azs."
  }
}

variable "nat_mode" {
  description = "NAT layout: none, single (one shared NAT gateway in the first AZ) or per_az (one NAT gateway and private route table per AZ)."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_mode)
    error_message = "nat_mode must be one of: none, single, per_az."
  }
}
