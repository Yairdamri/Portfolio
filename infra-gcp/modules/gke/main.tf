resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  release_channel {
    channel = var.release_channel
  }

  dynamic "ip_allocation_policy" {
    for_each = [1]
    content {
      cluster_secondary_range_name  = var.pods_secondary_range_name
      services_secondary_range_name = var.services_secondary_range_name
    }
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  workload_identity_config {
    workload_pool = var.workload_pool
  }

  dynamic "master_authorized_networks_config" {
    for_each = var.enable_master_authorized_networks ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks_cidrs
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = try(cidr_blocks.value.display_name, null)
        }
      }
    }
  }

  datapath_provider = "ADVANCED_DATAPATH"

  enable_shielded_nodes = true

  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  timeouts {
    create = "30m"
    update = "40m"
    delete = "30m"
  }
}

resource "google_container_node_pool" "primary" {
  project  = var.project_id
  name     = var.node_pool_name
  location = var.location
  cluster  = google_container_cluster.this.name

  node_locations = var.node_locations

  autoscaling {
    min_node_count = var.node_min_count
    max_node_count = var.node_max_count
  }

  node_config {
    preemptible  = var.node_preemptible
    machine_type = var.node_machine_type
    image_type   = var.node_image_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type
    labels       = var.node_labels
    tags         = var.node_tags

    service_account = var.node_service_account_email

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
