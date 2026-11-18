include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/ecs-alb-service"
}

locals {
  # Commit SHA of the image to deploy. It must already be published to ECR.
  image_tag = "b3753cb60f18fb2bc1e8b610b9d1c826543f443f"
}

dependency "vpc" {
  config_path = "../../vpc"

  mock_outputs = {
    vpc_id             = "mock-vpc-id"
    private_subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "alb" {
  config_path = "../../albs"

  mock_outputs = {
    dns_name          = "mock-alb.eu-north-1.elb.amazonaws.com"
    listener_arn      = "arn:aws:elasticloadbalancing:eu-north-1:017636909328:listener/app/mock/0000000000000000/0000000000000000"
    security_group_id = "sg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "cluster" {
  config_path = "../../ecs-cluster"

  mock_outputs = {
    cluster_arn = "arn:aws:ecs:eu-north-1:017636909328:cluster/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "ecr" {
  config_path = "../../ecr/status-api"

  mock_outputs = {
    repository_url = "017636909328.dkr.ecr.eu-north-1.amazonaws.com/mock"
    repository_arn = "arn:aws:ecr:eu-north-1:017636909328:repository/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name           = "status-api"
  image          = "${dependency.ecr.outputs.repository_url}:${local.image_tag}"
  container_port = 8080

  environment = {
    GREETING = "Hello from dev"
  }

  cpu                = 256
  memory             = 512
  desired_count      = 1
  log_retention_days = 30

  health_check = {
    path = "/health"
  }
  host_headers = [dependency.alb.outputs.dns_name]

  cluster_arn           = dependency.cluster.outputs.cluster_arn
  vpc_id                = dependency.vpc.outputs.vpc_id
  private_subnet_ids    = dependency.vpc.outputs.private_subnet_ids
  alb_listener_arn      = dependency.alb.outputs.listener_arn
  alb_security_group_id = dependency.alb.outputs.security_group_id
  ecr_repository_arn    = dependency.ecr.outputs.repository_arn
}
