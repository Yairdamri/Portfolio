variable "project_id" {
  description = "GCP project ID where Artifact Registry repositories will be created."
  type        = string
}

variable "repositories" {
  description = "List of Artifact Registry repositories to create."
  type = list(object({
    repository_id = string
    location      = string
    format        = string
    description   = optional(string)
    labels        = optional(map(string))
    kms_key_name  = optional(string)
  }))
}
