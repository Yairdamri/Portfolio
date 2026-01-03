locals {
  internal_ranges = [
    var.subnet_ip_cidr_range,
    var.pods_secondary_cidr,
    var.services_secondary_cidr
  ]
}

resource "google_compute_network" "this" {
  name                    = var.network_name
  description             = var.network_description
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "this" {
  name                     = var.subnet_name
  region                   = var.subnet_region
  ip_cidr_range            = var.subnet_ip_cidr_range
  network                  = google_compute_network.this.id
  private_ip_google_access = var.enable_private_google_access

  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_cidr
  }

  depends_on = [google_compute_network.this]
}

resource "google_compute_firewall" "allow_internal" {
  name      = "${var.network_name}-allow-internal"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 65534

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = local.internal_ranges
  target_tags   = []
  disabled      = false
  description   = "Allow internal traffic within primary and secondary ranges."
}

resource "google_compute_firewall" "allow_egress_all" {
  name      = "${var.network_name}-allow-egress"
  network   = google_compute_network.this.name
  direction = "EGRESS"
  priority  = 65534

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = []
  disabled           = false
  description        = "Allow all egress traffic."
}

resource "google_compute_router" "this" {
  name    = var.router_name
  region  = var.subnet_region
  network = google_compute_network.this.id

  depends_on = [google_compute_network.this]
}

resource "google_compute_router_nat" "this" {
  name                                = var.nat_name
  router                              = google_compute_router.this.name
  region                              = google_compute_router.this.region
  nat_ip_allocate_option              = var.nat_ip_allocate_option
  min_ports_per_vm                    = var.nat_min_ports_per_vm
  enable_endpoint_independent_mapping = var.nat_enable_endpoint_independent_mapping
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.enable_nat_logging
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_compute_router.this]
}

resource "google_compute_address" "ingress_ip" {
  count  = var.create_ingress_ip ? 1 : 0
  name   = coalesce(var.ingress_ip_name, "${var.network_name}-ingress-ip")
  region = var.subnet_region
  labels = var.labels
}
