include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/alb"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id            = "mock-vpc-id"
    public_subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                       = "self-service"
  vpc_id                     = dependency.vpc.outputs.vpc_id
  public_subnet_ids          = dependency.vpc.outputs.public_subnet_ids
  ingress_cidrs              = ["0.0.0.0/0"]
  enable_deletion_protection = false
}
