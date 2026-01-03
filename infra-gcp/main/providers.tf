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
  config_path    = "~/.kube/config"
  config_context = "gke_porfolio-480111_us-central1-a_workout-gke" # adjust to your context name
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "gke_porfolio-480111_us-central1-a_workout-gke"
  }
}
