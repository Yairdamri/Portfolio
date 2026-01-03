include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "gke" {
  config_path = "../gke"

  mock_outputs = {
    cluster_name = "workout-gke-prod"
    endpoint     = ""
    master_auth  = { cluster_ca_certificate = "" }
  }
  mock_outputs_allowed_terraform_commands = ["plan"]
}

locals {
  env_cfg   = read_terragrunt_config("${get_terragrunt_dir()}/../terragrunt.hcl")
  env       = local.env_cfg.locals.env
  project_id = local.env_cfg.locals.project_id
  region    = local.env_cfg.locals.region
  zone      = local.env_cfg.locals.zone
  repo_root  = abspath("${get_parent_terragrunt_dir("root")}/../..")
}

terraform {
  source = "../../../modules/argocd-gcp"
}

# Shared provider generation (kube/helm) for ArgoCD
include "kube_providers" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/common/argocd-kube-providers.hcl"
}

inputs = {
  namespace                = "argocd"
  # repo_url                 = "https://argoproj.github.io/argo-helm"
  values                   = ""
  applications_parent_path = "${local.repo_root}/argocd/applications-parent.yaml"
  infra_parent_path        = "${local.repo_root}/argocd/infra-parent.yaml"
  project_id               = local.project_id
  gitops_repo_url          = "git@github.com:Yairdamri/argocd-gitops.git"
  gitops_secret_id         = "gitops"
  k8s_repo_url             = "git@github.com:Yairdamri/k8s-infra.git"
  k8s_secret_id            = "k8s-secert"
  wait_for_ready           = "30s"
}
