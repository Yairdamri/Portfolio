# Inject Kubernetes/Helm providers using the GKE outputs
generate "kube_providers" {
  path      = "kube.auto.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${dependency.gke.outputs.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode("${dependency.gke.outputs.master_auth.cluster_ca_certificate}")
}

provider "helm" {
  kubernetes {
    host                   = "https://${dependency.gke.outputs.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode("${dependency.gke.outputs.master_auth.cluster_ca_certificate}")
  }
}
EOF
}
