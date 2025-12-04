output "cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.this.name
}

output "location" {
  description = "Cluster location."
  value       = google_container_cluster.this.location
}

output "endpoint" {
  description = "GKE master endpoint."
  value       = google_container_cluster.this.endpoint
}

output "master_auth" {
  description = "Cluster CA certificate for authentication."
  value = {
    cluster_ca_certificate = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  }
}

output "workload_identity_pool" {
  description = "Workload Identity pool."
  value       = google_container_cluster.this.workload_identity_config[0].workload_pool
}

output "node_pool_name" {
  description = "Node pool name."
  value       = google_container_node_pool.primary.name
}

output "node_service_account_email" {
  description = "Node service account email."
  value       = var.node_service_account_email
}
