locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  account_id          = local.account_vars.locals.account_id
  env                 = local.account_vars.locals.env
  state_bucket        = local.account_vars.locals.state_bucket
  state_bucket_region = local.account_vars.locals.state_bucket_region
  aws_region          = local.region_vars.locals.aws_region
}

remote_state {
  backend = "s3"
  config = {
    bucket       = local.state_bucket
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.state_bucket_region
    encrypt      = true
    use_lockfile = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region              = "${local.aws_region}"
      allowed_account_ids = ["${local.account_id}"]

      default_tags {
        tags = {
          Environment = "${local.env}"
          ManagedBy   = "terragrunt"
        }
      }
    }
  EOF
}
