variable "project_id" {
  description = "GCP project ID for the cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "location" {
  description = "Zone or region for the GKE cluster (e.g., us-central1-a for zonal)."
  type        = string
}

variable "network" {
  description = "VPC network self link."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self link."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary range for pods."
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary range for services."
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master IPv4 range (for private cluster control plane)."
  type        = string
  default     = "172.16.0.0/28"
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)."
  type        = string
  default     = "REGULAR"
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version override."
  type        = string
  default     = null
}

variable "enable_private_nodes" {
  description = "Whether to create private nodes without public IPs."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether to disable the public control plane endpoint."
  type        = bool
  default     = false
}

variable "enable_master_authorized_networks" {
  description = "Whether to enable master authorized networks."
  type        = bool
  default     = false
}

variable "master_authorized_networks_cidrs" {
  description = "List of CIDRs allowed to reach the master if master authorized networks is enabled."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []
}

variable "workload_pool" {
  description = "Workload Identity pool (e.g., <PROJECT_ID>.svc.id.goog)."
  type        = string
}

variable "node_pool_name" {
  description = "Name of the default node pool."
  type        = string
  default     = "default-pool"
}

variable "node_locations" {
  description = "Optional list of zones for node pool within the cluster location."
  type        = list(string)
  default     = []
}

variable "node_machine_type" {
  description = "Machine type for nodes."
  type        = string
  default     = "e2-medium"
}

variable "node_disk_size_gb" {
  description = "Disk size in GB for nodes."
  type        = number
  default     = 50
}

variable "node_disk_type" {
  description = "Disk type for nodes (pd-standard or pd-balanced)."
  type        = string
  default     = "pd-balanced"
}

variable "node_image_type" {
  description = "Node image type."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "node_preemptible" {
  description = "Whether nodes are preemptible (cheaper, less reliable)."
  type        = bool
  default     = true
}

variable "node_min_count" {
  description = "Minimum nodes for autoscaling."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes for autoscaling."
  type        = number
  default     = 2
}

variable "node_service_account_email" {
  description = "Service account email for node pool VMs."
  type        = string
}

variable "node_labels" {
  description = "Labels to apply to nodes."
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags to apply to nodes."
  type        = list(string)
  default     = []
}
