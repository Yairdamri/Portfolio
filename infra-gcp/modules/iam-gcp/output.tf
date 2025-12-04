output "node_service_account_email" {
  description = "Email of the GKE node pool service account."
  value       = google_service_account.node.email
}

output "node_service_account_unique_id" {
  description = "Unique ID of the GKE node pool service account."
  value       = google_service_account.node.unique_id
}
