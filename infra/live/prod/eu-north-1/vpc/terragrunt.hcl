include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  name            = "self-service"
  cidr            = "10.20.0.0/16"
  azs             = ["eu-north-1a", "eu-north-1b"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24"]
  private_subnets = ["10.20.0.0/20", "10.20.16.0/20"]
  nat_mode        = "per_az"
}
