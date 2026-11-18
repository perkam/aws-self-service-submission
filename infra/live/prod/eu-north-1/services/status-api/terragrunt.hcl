include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/ecs-alb-service"
}

locals {
  # Image used when the service is first created. The pipeline deploys later releases.
  initial_image_tag = "b3753cb60f18fb2bc1e8b610b9d1c826543f443f"

  # Prod pulls the images tested on dev from the shared ECR repository.
  ecr_repository_url = "017636909328.dkr.ecr.eu-north-1.amazonaws.com/status-api"
  ecr_repository_arn = "arn:aws:ecr:eu-north-1:017636909328:repository/status-api"
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
    listener_arn      = "arn:aws:elasticloadbalancing:eu-north-1:000000000000:listener/app/mock/0000000000000000/0000000000000000"
    security_group_id = "sg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "cluster" {
  config_path = "../../ecs-cluster"

  mock_outputs = {
    cluster_arn = "arn:aws:ecs:eu-north-1:000000000000:cluster/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "github_oidc" {
  config_path = "../../iam/github-oidc"

  mock_outputs = {
    provider_arn = "arn:aws:iam::000000000000:oidc-provider/token.actions.githubusercontent.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name           = "status-api"
  image          = "${local.ecr_repository_url}:${local.initial_image_tag}"
  container_port = 8080

  environment = {
    GREETING = "Hello from prod"
  }

  cpu                = 256
  memory             = 512
  desired_count      = 2
  log_retention_days = 30

  keep_logs_on_destroy = true

  health_check = {
    path = "/health"
  }
  host_headers = [dependency.alb.outputs.dns_name]

  cluster_arn           = dependency.cluster.outputs.cluster_arn
  vpc_id                = dependency.vpc.outputs.vpc_id
  private_subnet_ids    = dependency.vpc.outputs.private_subnet_ids
  alb_listener_arn      = dependency.alb.outputs.listener_arn
  alb_security_group_id = dependency.alb.outputs.security_group_id
  ecr_repository_arn    = local.ecr_repository_arn

  github_repository        = "perkam@15228551/aws-self-service-submission@1462922734"
  github_environment       = "prod"
  github_oidc_provider_arn = dependency.github_oidc.outputs.provider_arn
}
