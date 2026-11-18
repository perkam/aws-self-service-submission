include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/ecr"
}

dependency "github_oidc" {
  config_path = "../../iam/github-oidc"

  mock_outputs = {
    provider_arn = "arn:aws:iam::017636909328:oidc-provider/token.actions.githubusercontent.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                     = "status-api"
  github_repository        = "perkam@15228551/aws-self-service-submission@1462922734"
  github_oidc_provider_arn = dependency.github_oidc.outputs.provider_arn
}
