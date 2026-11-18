include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/ecs-cluster"
}

inputs = {
  name               = "self-service"
  container_insights = "enhanced"
}
