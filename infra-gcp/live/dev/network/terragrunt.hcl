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
  source = "../../../modules/network-gcp"
}

inputs = {
  project_id                           = local.project_id
  network_name                         = "gke-network-${local.env}"
  network_description                  = "GKE network (${local.env})"
  routing_mode                         = "REGIONAL"
  subnet_name                          = "gke-subnet-${local.env}"
  subnet_region                        = local.region
  subnet_ip_cidr_range                 = "10.10.0.0/23"
  pods_secondary_range_name            = "pods"
  pods_secondary_cidr                  = "10.20.0.0/18"
  services_secondary_range_name        = "services"
  services_secondary_cidr              = "10.30.0.0/22"
  enable_private_google_access         = true
  router_name                          = "gke-router-${local.env}"
  nat_name                             = "gke-nat-${local.env}"
  nat_ip_allocate_option               = "AUTO_ONLY"
  nat_min_ports_per_vm                 = 64
  nat_enable_endpoint_independent_mapping = true
  enable_nat_logging                   = false
  create_ingress_ip                    = true
  ingress_ip_name                      = "ingress-static-ip-${local.env}"
  labels                               = { env = local.env, stack = "gke" }
}
