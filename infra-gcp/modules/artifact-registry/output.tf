output "repositories" {
  description = "Artifact Registry repository details."
  value = {
    for k, repo in google_artifact_registry_repository.this :
    k => {
      id          = repo.id
      name        = repo.name
      format      = repo.format
      location    = repo.location
      docker_repo = repo.format == "DOCKER" ? "${repo.location}-docker.pkg.dev/${repo.project}/${repo.repository_id}" : null
    }
  }
}
