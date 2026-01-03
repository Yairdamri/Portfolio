output "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  value       = var.namespace
}

# output "argocd_release_name" {
#   description = "Argo CD Helm release name."
#   value       = helm_release.argocd.name
# }
