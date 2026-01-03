# resource "helm_release" "argocd" {
#   name             = "argocd"
#   repository       = var.repo_url
#   chart            = "argo-cd"
#   namespace        = var.namespace
#   create_namespace = true

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }

#   values = var.values != "" ? [var.values] : []
# }

resource "time_sleep" "wait_for_crds" {
  # depends_on      = [helm_release.argocd]
  create_duration = var.wait_for_ready # consider bumping to "90s" or "120s"
}

resource "time_sleep" "wait_for_argocd" {
  # depends_on      = [helm_release.argocd]
  create_duration = var.wait_for_ready
}

# Optional repo SSH secrets from Secret Manager
data "google_secret_manager_secret_version" "gitops_key" {
  count   = var.gitops_secret_id != "" ? 1 : 0
  project = var.project_id
  secret  = var.gitops_secret_id
}

data "google_secret_manager_secret_version" "k8s_key" {
  count   = var.k8s_secret_id != "" ? 1 : 0
  project = var.project_id
  secret  = var.k8s_secret_id
}

resource "kubernetes_secret" "gitops_repo" {
  count = var.gitops_secret_id != "" ? 1 : 0

  metadata {
    name      = "gitops"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.gitops_repo_url
    sshPrivateKey = data.google_secret_manager_secret_version.gitops_key[0].secret_data
  }

  type       = "Opaque"
  depends_on = [time_sleep.wait_for_argocd]
}

resource "kubernetes_secret" "k8s_repo" {
  count = var.k8s_secret_id != "" ? 1 : 0

  metadata {
    name      = "k8s-secret"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.k8s_repo_url
    sshPrivateKey = data.google_secret_manager_secret_version.k8s_key[0].secret_data
  }

  type       = "Opaque"
  depends_on = [time_sleep.wait_for_argocd]
}

resource "kubernetes_manifest" "applications_parent" {
  depends_on = [
    # helm_release.argocd,
    time_sleep.wait_for_crds,
    time_sleep.wait_for_argocd,
  ]
  manifest = yamldecode(file(var.applications_parent_path))
}

resource "kubernetes_manifest" "infra_parent" {
  depends_on = [
    # helm_release.argocd,
    time_sleep.wait_for_crds,
    time_sleep.wait_for_argocd,
    kubernetes_manifest.applications_parent
  ]
  manifest = yamldecode(file(var.infra_parent_path))
}
