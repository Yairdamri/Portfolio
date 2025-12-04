resource "google_service_account" "node" {
  project      = var.project_id
  account_id   = var.node_service_account_name
  display_name = var.node_service_account_display_name
  description  = var.node_service_account_description
}

resource "google_project_iam_member" "node_roles" {
  for_each = toset(var.node_service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node.email}"
}
