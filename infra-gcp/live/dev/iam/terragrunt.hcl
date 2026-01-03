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
  source = "../../../modules/iam-gcp"
}

inputs = {
  project_id                        = local.project_id
  node_service_account_name         = "gke-node-sa"
  node_service_account_display_name = "GKE Node Service Account"
  node_service_account_description  = "Node SA for GKE (${local.env})"
  node_service_account_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",
  ]
}
