provider "google" {
  project = var.project_id
  region  = var.subnet_region
}

provider "google-beta" {
  project = var.project_id
  region  = var.subnet_region
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host  = module.gke.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    module.gke.master_auth.cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = module.gke.endpoint
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      module.gke.master_auth.cluster_ca_certificate
    )
  }
}
