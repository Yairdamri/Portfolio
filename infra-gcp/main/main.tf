module "network" {
  source = "../modules/network-gcp"

  network_name                           = var.network_name
  network_description                    = var.network_description
  routing_mode                           = var.routing_mode
  subnet_name                            = var.subnet_name
  subnet_region                          = var.subnet_region
  subnet_ip_cidr_range                   = var.subnet_ip_cidr_range
  pods_secondary_range_name              = var.pods_secondary_range_name
  pods_secondary_cidr                    = var.pods_secondary_cidr
  services_secondary_range_name          = var.services_secondary_range_name
  services_secondary_cidr                = var.services_secondary_cidr
  enable_private_google_access           = var.enable_private_google_access
  router_name                            = var.router_name
  nat_name                               = var.nat_name
  nat_ip_allocate_option                 = var.nat_ip_allocate_option
  nat_min_ports_per_vm                   = var.nat_min_ports_per_vm
  nat_enable_endpoint_independent_mapping = var.nat_enable_endpoint_independent_mapping
  enable_nat_logging                     = var.enable_nat_logging
  labels                                 = var.network_labels
}

module "iam" {
  source = "../modules/iam-gcp"

  project_id                           = var.project_id
  node_service_account_name            = var.node_service_account_name
  node_service_account_display_name    = var.node_service_account_display_name
  node_service_account_description     = var.node_service_account_description
  node_service_account_roles           = var.node_service_account_roles
}

module "artifact_registry" {
  source = "../modules/artifact-registry"

  project_id    = var.project_id
  repositories  = var.artifact_repositories
}

module "gke" {
  source = "../modules/gke"

  project_id                        = var.project_id
  cluster_name                      = var.gke_cluster_name
  location                          = var.gke_location
  network                           = module.network.network_self_link
  subnetwork                        = module.network.subnet_self_link
  pods_secondary_range_name         = module.network.pods_secondary_range.name
  services_secondary_range_name     = module.network.services_secondary_range.name
  master_ipv4_cidr_block            = var.gke_master_ipv4_cidr_block
  release_channel                   = var.gke_release_channel
  kubernetes_version                = var.gke_kubernetes_version
  enable_private_nodes              = var.gke_enable_private_nodes
  enable_private_endpoint           = var.gke_enable_private_endpoint
  enable_master_authorized_networks = var.gke_enable_master_authorized_networks
  master_authorized_networks_cidrs  = var.gke_master_authorized_networks_cidrs
  workload_pool                     = "${var.project_id}.svc.id.goog"
  node_pool_name                    = var.gke_node_pool_name
  node_locations                    = var.gke_node_locations
  node_machine_type                 = var.gke_node_machine_type
  node_disk_size_gb                 = var.gke_node_disk_size_gb
  node_disk_type                    = var.gke_node_disk_type
  node_image_type                   = var.gke_node_image_type
  node_preemptible                  = var.gke_node_preemptible
  node_min_count                    = var.gke_node_min_count
  node_max_count                    = var.gke_node_max_count
  node_service_account_email        = module.iam.node_service_account_email
  node_labels                       = var.gke_node_labels
  node_tags                         = var.gke_node_tags
}

resource "google_compute_address" "ingress_ip" {
  name   = var.ingress_global_ip_name
  region = var.subnet_region
}

# External Secrets: allow WI and Secret Manager access for the GSA
resource "google_service_account_iam_member" "external_secrets_wi" {
  count              = var.external_secrets_gsa_email == null ? 0 : 1
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.external_secrets_gsa_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets]"
}

resource "google_project_iam_member" "external_secrets_sm" {
  count   = var.external_secrets_gsa_email == null ? 0 : 1
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${var.external_secrets_gsa_email}"
}

module "argocd" {
  source = "../modules/argocd-gcp"

  namespace                = "argocd"
  repo_url                 = "https://argoproj.github.io/argo-helm"
  # chart_name               = "argo-cd"
  # chart_version            = "5.51.6"
  values                   = ""
  applications_parent_path = "${path.root}/../../argocd/applications-parent.yaml"
  infra_parent_path        = "${path.root}/../../argocd/infra-parent.yaml"

  depends_on = [
    module.gke
  ]
}
