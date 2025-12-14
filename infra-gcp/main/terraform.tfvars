# Network
network_name                          = "gke-network"
network_description                   = "GKE test network"
routing_mode                          = "REGIONAL"
subnet_name                           = "gke-subnet"
subnet_region                         = "us-central1"
subnet_ip_cidr_range                  = "10.10.0.0/23"
pods_secondary_range_name             = "pods"
pods_secondary_cidr                   = "10.20.0.0/18"
services_secondary_range_name         = "services"
services_secondary_cidr               = "10.30.0.0/22"
enable_private_google_access          = true
router_name                           = "gke-router"
nat_name                              = "gke-nat"
nat_ip_allocate_option                = "AUTO_ONLY"
nat_min_ports_per_vm                  = 64
nat_enable_endpoint_independent_mapping = true
enable_nat_logging                    = false
network_labels                        = { env = "test", stack = "gke" }

# IAM
project_id                          = "your-gcp-project-id"
node_service_account_name           = "gke-node-sa"
node_service_account_display_name   = "GKE Node Service Account"
node_service_account_description    = "Node SA for GKE test cluster"
node_service_account_roles          = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/artifactregistry.reader"
]

# Artifact Registry
artifact_repositories = [
  {
    repository_id = "workout-backend"
    location      = "us-central1"
    format        = "DOCKER"
    description   = "Backend images"
    labels        = { env = "test", app = "backend" }
  },
  {
    repository_id = "workout-frontend"
    location      = "us-central1"
    format        = "DOCKER"
    description   = "Frontend images"
    labels        = { env = "test", app = "frontend" }
  }
]

# GKE
gke_cluster_name                       = "workout-gke"
gke_location                           = "us-central1-a"
gke_master_ipv4_cidr_block             = "172.16.0.0/28"
gke_release_channel                    = "REGULAR"
gke_kubernetes_version                 = null
gke_enable_private_nodes               = true
gke_enable_private_endpoint            = false
gke_enable_master_authorized_networks  = false
gke_master_authorized_networks_cidrs   = []
gke_node_pool_name                     = "default-pool"
gke_node_locations                     = []
gke_node_machine_type                  = "e2-medium"
gke_node_disk_size_gb                  = 50
gke_node_disk_type                     = "pd-balanced"
gke_node_image_type                    = "COS_CONTAINERD"
gke_node_preemptible                   = false
gke_node_min_count                     = 1
gke_node_max_count                     = 2
gke_node_labels                        = { env = "test" }
gke_node_tags                          = []

# Ingress
ingress_global_ip_name   = "ingress-static-ip"
