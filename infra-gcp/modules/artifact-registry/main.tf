resource "google_artifact_registry_repository" "this" {
  for_each = { for repo in var.repositories : repo.repository_id => repo }

  project       = var.project_id
  location      = each.value.location
  repository_id = each.value.repository_id
  format        = each.value.format
  description   = lookup(each.value, "description", null)
  labels        = lookup(each.value, "labels", null)
  kms_key_name  = lookup(each.value, "kms_key_name", null)

  dynamic "docker_config" {
    for_each = each.value.format == "DOCKER" ? [1] : []
    content {
      immutable_tags = false
    }
  }

}
