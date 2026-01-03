output "network_name" {
  description = "VPC network name."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "Self link of the VPC network."
  value       = google_compute_network.this.self_link
}

output "subnet_name" {
  description = "Primary subnet name."
  value       = google_compute_subnetwork.this.name
}

output "subnet_self_link" {
  description = "Self link of the primary subnet."
  value       = google_compute_subnetwork.this.self_link
}

output "subnet_region" {
  description = "Region of the primary subnet."
  value       = google_compute_subnetwork.this.region
}

output "subnet_cidr" {
  description = "Primary subnet CIDR."
  value       = google_compute_subnetwork.this.ip_cidr_range
}

output "pods_secondary_range" {
  description = "Pods secondary range details."
  value = {
    name = var.pods_secondary_range_name
    cidr = var.pods_secondary_cidr
  }
}

output "services_secondary_range" {
  description = "Services secondary range details."
  value = {
    name = var.services_secondary_range_name
    cidr = var.services_secondary_cidr
  }
}

output "router_name" {
  description = "Cloud Router name."
  value       = google_compute_router.this.name
}

output "nat_name" {
  description = "Cloud NAT name."
  value       = google_compute_router_nat.this.name
}

output "ingress_ip" {
  description = "Ingress static IP (if created)."
  value = length(google_compute_address.ingress_ip) > 0 ? {
    name = google_compute_address.ingress_ip[0].name
    ip   = google_compute_address.ingress_ip[0].address
  } : null
}
