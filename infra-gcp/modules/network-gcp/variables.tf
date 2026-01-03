variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "network_description" {
  description = "Description for the VPC network."
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode (REGIONAL or GLOBAL)."
  type        = string
}

variable "subnet_name" {
  description = "Name of the primary subnet."
  type        = string
}

variable "subnet_region" {
  description = "Region for the subnet."
  type        = string
}

variable "subnet_ip_cidr_range" {
  description = "Primary CIDR range for the subnet."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary range for pods."
  type        = string
}

variable "pods_secondary_cidr" {
  description = "CIDR block for the pods secondary range."
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary range for services."
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
  description = "Whether to enable NAT logging (can increase costs slightly)."
  type        = bool
}

variable "create_ingress_ip" {
  description = "Whether to reserve a regional static IP for ingress."
  type        = bool
  default     = false
}

variable "ingress_ip_name" {
  description = "Name of the reserved ingress IP (required if create_ingress_ip is true)."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to network resources."
  type        = map(string)
}
