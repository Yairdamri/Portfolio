variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "network_description" {
  description = "Description for the VPC network."
  type        = string
  default     = ""
}

variable "routing_mode" {
  description = "VPC routing mode (REGIONAL or GLOBAL)."
  type        = string
  default     = "REGIONAL"
}

variable "subnet_name" {
  description = "Name of the primary subnet."
  type        = string
}

variable "subnet_region" {
  description = "Region for the primary subnet."
  type        = string
}

variable "subnet_ip_cidr_range" {
  description = "Primary CIDR range for the subnet."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the pods secondary range."
  type        = string
}

variable "pods_secondary_cidr" {
  description = "CIDR block for the pods secondary range."
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the services secondary range."
  type        = string
}

variable "services_secondary_cidr" {
  description = "CIDR block for the services secondary range."
  type        = string
}

variable "enable_private_google_access" {
  description = "Whether to enable Private Google Access on the subnet."
  type        = bool
}

variable "router_name" {
  description = "Name of the Cloud Router."
  type        = string
}

variable "nat_name" {
  description = "Name of the Cloud NAT configuration."
  type        = string
}

variable "nat_ip_allocate_option" {
  description = "NAT IP allocation option (AUTO_ONLY or MANUAL_ONLY)."
  type        = string
}

variable "nat_min_ports_per_vm" {
  description = "Minimum ports per VM for NAT."
  type        = number
}

variable "nat_enable_endpoint_independent_mapping" {
  description = "Whether to enable endpoint-independent mapping for NAT."
  type        = bool
}

variable "enable_nat_logging" {
  description = "Whether to enable NAT logging."
  type        = bool
}

variable "network_labels" {
  description = "Labels to apply to network resources."
  type        = map(string)
  default     = {}
}

# IAM
variable "project_id" {
  description = "GCP project ID for resources."
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

# Artifact Registry
variable "artifact_repositories" {
  description = "List of Artifact Registry repositories to create."
  type = list(object({
    repository_id = string
    location      = string
    format        = string
    description   = optional(string)
    labels        = optional(map(string))
    kms_key_name  = optional(string)
  }))
}

# GKE
variable "gke_cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "gke_location" {
  description = "Zone or region for the GKE cluster."
  type        = string
}

variable "gke_master_ipv4_cidr_block" {
  description = "CIDR block for the master IPv4 range."
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"
}

variable "gke_kubernetes_version" {
  description = "Optional Kubernetes version override."
  type        = string
  default     = null
}

variable "gke_enable_private_nodes" {
  description = "Whether to create private nodes."
  type        = bool
  default     = true
}

variable "gke_enable_private_endpoint" {
  description = "Whether to disable the public control plane endpoint."
  type        = bool
  default     = false
}

variable "gke_enable_master_authorized_networks" {
  description = "Whether to enable master authorized networks."
  type        = bool
  default     = false
}

variable "gke_master_authorized_networks_cidrs" {
  description = "CIDRs allowed to reach the master if master authorized networks is enabled."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []
}

variable "gke_node_pool_name" {
  description = "Name of the default node pool."
  type        = string
  default     = "default-pool"
}

variable "gke_node_locations" {
  description = "Optional list of zones for the node pool."
  type        = list(string)
  default     = []
}

variable "gke_node_machine_type" {
  description = "Machine type for nodes."
  type        = string
  default     = "e2-medium"
}

variable "gke_node_disk_size_gb" {
  description = "Disk size for nodes."
  type        = number
  default     = 50
}

variable "gke_node_disk_type" {
  description = "Disk type for nodes."
  type        = string
  default     = "pd-balanced"
}

variable "gke_node_image_type" {
  description = "Node image type."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "gke_node_preemptible" {
  description = "Whether nodes are preemptible."
  type        = bool
  default     = false
}

variable "gke_node_min_count" {
  description = "Minimum node count."
  type        = number
  default     = 1
}

variable "gke_node_max_count" {
  description = "Maximum node count."
  type        = number
  default     = 2
}

variable "gke_node_labels" {
  description = "Labels to apply to nodes."
  type        = map(string)
  default     = {}
}

variable "gke_node_tags" {
  description = "Network tags to apply to nodes."
  type        = list(string)
  default     = []
}

# Ingress
variable "ingress_global_ip_name" {
  description = "Name for the reserved global static IP used by ingress."
  type        = string
  default     = "ingress-static-ip"
}
