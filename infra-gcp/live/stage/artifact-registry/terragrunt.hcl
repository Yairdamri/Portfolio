include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg   = read_terragrunt_config("${get_terragrunt_dir()}/../terragrunt.hcl")
  env       = local.env_cfg.locals.env
  project_id = local.env_cfg.locals.project_id
  region    = local.env_cfg.locals.region
  zone      = local.env_cfg.locals.zone
}

terraform {
  source = "../../../modules/artifact-registry"
}

inputs = {
  project_id = local.project_id
  repositories = [
    {
      repository_id = "workout-backend-${local.env}"
      location      = local.region
      format        = "DOCKER"
      description   = "Backend images (${local.env})"
      labels        = { env = local.env, app = "backend" }
    },
    {
      repository_id = "workout-frontend-${local.env}"
      location      = local.region
      format        = "DOCKER"
      description   = "Frontend images (${local.env})"
      labels        = { env = local.env, app = "frontend" }
    }
  ]
}
