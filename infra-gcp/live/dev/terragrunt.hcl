include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env       = "dev"
  root_cfg  = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  project_id = local.root_cfg.locals.project_id
  region    = local.root_cfg.locals.region
  zone      = local.root_cfg.locals.zone
}

# Environment-wide overrides or shared inputs can go here.
inputs = {
  env = local.env
}
