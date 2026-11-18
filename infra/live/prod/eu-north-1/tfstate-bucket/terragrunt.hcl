include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/tfstate-bucket"
}

# BOOTSTRAP ONLY: comment out this block after the first apply,
# then run `terragrunt init -migrate-state` to move state into S3.
#remote_state {
#  backend = "local"
#  config = {
#    path = "${get_terragrunt_dir()}/terraform.tfstate"
#  }
#  generate = {
#    path      = "backend.tf"
#    if_exists = "overwrite_terragrunt"
#  }
#}

inputs = {
  bucket_name = include.root.locals.state_bucket
}
