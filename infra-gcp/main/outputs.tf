output "network" {
  description = "Network outputs."
  value = {
    name                 = module.network.network_name
    self_link            = module.network.network_self_link
    subnet_name          = module.network.subnet_name
    subnet_self_link     = module.network.subnet_self_link
    subnet_region        = module.network.subnet_region
    subnet_cidr          = module.network.subnet_cidr
    pods_secondary_range = module.network.pods_secondary_range
    services_secondary   = module.network.services_secondary_range
    router_name          = module.network.router_name
    nat_name             = module.network.nat_name
  }
}

output "iam" {
  description = "IAM outputs."
  value = {
    node_service_account_email     = module.iam.node_service_account_email
    node_service_account_unique_id = module.iam.node_service_account_unique_id
  }
}

output "artifact_registry" {
  description = "Artifact Registry repositories."
  value       = module.artifact_registry.repositories
}

output "gke" {
  description = "GKE cluster details."
  value = {
    cluster_name              = module.gke.cluster_name
    location                  = module.gke.location
    endpoint                  = module.gke.endpoint
    master_auth               = module.gke.master_auth
    workload_identity_pool    = module.gke.workload_identity_pool
    node_pool_name            = module.gke.node_pool_name
    node_service_account_email = module.gke.node_service_account_email
  }
}

output "ingress_global_ip" {
  description = "Reserved global static IP for ingress."
  value = {
    name = google_compute_address.ingress_ip.name
    ip   = google_compute_address.ingress_ip.address
  }
}
