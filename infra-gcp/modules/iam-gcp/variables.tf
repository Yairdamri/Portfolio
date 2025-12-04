variable "project_id" {
  description = "GCP project ID where IAM resources will be created."
  type        = string
}

variable "node_service_account_name" {
  description = "Service account ID (short name) for GKE node pool VMs."
  type        = string
}

variable "node_service_account_display_name" {
  description = "Display name for the node service account."
  type        = string
}

variable "node_service_account_description" {
  description = "Description for the node service account."
  type        = string
}

variable "node_service_account_roles" {
  description = "List of IAM roles to bind to the node service account."
  type        = list(string)
}
