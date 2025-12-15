# GCP Migration Task List

Use this as a checklist to stand up the new GCP stack and cut over from AWS/Jenkins.

## Bootstrap
- [ ] Confirm target GCP project and billing.
- [ ] Enable required APIs: Compute, Gke, Artifact Registry, Secret Manager, Cloud Logging/Monitoring, IAM, KMS (if needed).
- [ ] Create or choose a Terraform state bucket (GCS) and locking mechanism.
- [ ] Wire Terraform backend config to the state bucket.
- [ ] Create a CI/service account with least-privilege roles for infra apply (network admin, container admin, artifactregistry admin/writer, iam.serviceAccountAdmin/User, secretmanager admin if used).

## Repository Scaffolding
- [ ] Create `infra-gcp/` root.
- [ ] Add providers/versions files.
- [ ] Add variables definitions.
- [ ] Add `tfvars.example`.
- [ ] Add `main.tf` and `outputs.tf` wired to modules.
- [ ] Create modules: `network-gcp`, `iam-gcp`, `artifact-registry`, `gke`, `argocd-gcp`.
- [ ] (Optional) Create modules: `kms`, `secret-manager`.

## Network
- [ ] Design VPC CIDR and secondary ranges for pods/services.
- [ ] Create VPC.
- [ ] Create subnets per environment.
- [ ] Create Cloud Router and Cloud NAT.
- [ ] Create firewall rules.
- [ ] Output subnet and secondary ranges for cluster consumption.

## IAM
- [ ] Create node pool service account with minimal scopes.
- [ ] Enable Workload Identity on the cluster.
- [ ] Create workload service accounts and bindings for apps that need GCP APIs.

## Artifact Registry
- [ ] Create Docker repo(s) (backend/frontend or shared) in target region.
- [ ] Attach KMS key to repo (optional).
- [ ] Document repo URLs for Helm values and CI push steps.

## GKE
- [ ] Create cluster (private/public API as decided) with IP aliasing using network outputs.
- [ ] Enable Workload Identity on the cluster.
- [ ] Configure node pools (sizes, autoscaling, taints/labels as needed).
- [ ] Expose outputs: kube endpoint, CA, Workload Identity pool, node service account email.

## Kube/Helm Providers
- [ ] Configure `kubernetes` provider from cluster outputs.
- [ ] Configure `helm` provider from cluster outputs.
- [ ] Add data source for cluster credentials if needed.

## Ingress & TLS
- [ ] Choose ingress strategy (GCLB Ingress vs NGINX).
- [ ] Deploy ingress controller.
- [ ] Set up cert-manager with Cloud DNS/HTTP01 solver.
- [ ] Provision TLS for domains.

## ArgoCD
- [ ] Install ArgoCD via Helm using `argocd-gcp` module.
- [ ] Replace AWS Secrets Manager with Secret Manager or direct K8s secrets for repo creds.
- [ ] Point app-of-apps to GitHub repos.
- [ ] Update destination server/namespace for GKE.

## Helm Values & Manifests
- [ ] Update all image repositories to Artifact Registry URLs in charts (`workout-*` values).
- [ ] Adjust storage classes to match GKE.
- [ ] Adjust ingress annotations to match GKE.

## CI/CD
- [ ] Create GitHub Actions secrets (GCP SA key, project, region, Artifact Registry repo, cluster info).
- [ ] Update workflows to run `gcloud auth activate-service-account`.
- [ ] Update workflows to run `gcloud auth configure-docker`.
- [ ] Update workflows to build/tag/push to Artifact Registry.
- [ ] Update workflows to deploy/signal ArgoCD.
- [ ] Decommission Jenkins stages once Actions pipeline is green.

## Secrets Management
- [ ] Migrate sensitive values to Secret Manager.
- [ ] Wire External Secrets/CSI driver into the cluster if needed.

## Observability
- [ ] Ensure Cloud Logging enabled.
- [ ] Ensure Cloud Monitoring enabled.
- [ ] Deploy Managed Prometheus/Grafana (optional).
- [ ] Add alerting policies.

## Cutover & Cleanup
- [ ] Smoke test on GKE (unit/integration/e2e).
- [ ] Validate ArgoCD sync and ingress.
- [ ] Switch traffic/DNS.
- [ ] Monitor after cutover.
- [ ] Keep roll back plan ready.
- [ ] Clean up AWS resources and credentials once stable.

## Terragrunt Adoption (Terraform)
- [ ] Add a root `terragrunt.hcl` with remote_state (GCS) and common provider settings (project/region).
- [ ] Create per-environment folders (e.g., `envs/dev/terragrunt.hcl`) pointing to `infra-gcp/main` as the source.
- [ ] Migrate `terraform.tfvars` inputs into Terragrunt `inputs` per environment.
- [ ] Configure GCS backend (bucket/prefix) via Terragrunt and remove local backend from the module.
- [ ] Test `terragrunt init/plan/apply` for one environment and migrate state to GCS.
- [ ] Update CI to use Terragrunt and ignore local Terraform state; add `.terragrunt-cache/` to gitignore if not present..
