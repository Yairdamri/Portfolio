variable "namespace" {
  description = "Namespace where Argo CD will be installed."
  type        = string
  default     = "argocd"
}

variable "project_id" {
  description = "Project ID (used for Secret Manager lookups)."
  type        = string
}

variable "repo_url" {
  description = "Helm chart repository URL for Argo CD."
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "values" {
  description = "Optional Helm values as a YAML string."
  type        = string
  default     = ""
}

variable "applications_parent_path" {
  description = "Path to the ArgoCD applications-parent.yaml file."
  type        = string
  default     = ""
}

variable "infra_parent_path" {
  description = "Path to the ArgoCD infra-parent.yaml file."
  type        = string
  default     = ""
}

variable "wait_for_ready" {
  description = "Duration to wait after installing Argo CD before applying parent apps."
  type        = string
  default     = "30s"
}

# Optional git repo wiring (SSH) via Secret Manager
variable "gitops_repo_url" {
  description = "SSH URL for the argocd-gitops repo."
  type        = string
  default     = ""
}

variable "gitops_secret_id" {
  description = "Secret Manager secret ID containing the private key for the argocd-gitops repo."
  type        = string
  default     = ""
}

variable "k8s_repo_url" {
  description = "SSH URL for the k8s-infra repo."
  type        = string
  default     = ""
}

variable "k8s_secret_id" {
  description = "Secret Manager secret ID containing the private key for the k8s-infra repo."
  type        = string
  default     = ""
}
