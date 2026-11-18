include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  name            = "self-service"
  cidr            = "10.10.0.0/16"
  azs             = ["eu-north-1a", "eu-north-1b"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  nat_mode        = "single"
}
