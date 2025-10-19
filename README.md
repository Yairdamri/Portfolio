# Workout Generator & Tracker Portfolio

Full-stack fitness platform demonstrating application delivery, GitOps, and infrastructure automation

## Quick Links

- Backend FastAPI app → `app/`
- Frontend React SPA → `frontend/`
- Terraform infrastructure → `infra/`
- Helm charts for Kubernetes → `k8s/`
- ArgoCD GitOps definitions → `argocd/`
- Test & automation scripts → `scripts/`, `tests/`

## Overview

The system generates personalized workout plans, tracks training history, and surfaces live metrics. It pairs a FastAPI backend and React frontend with MongoDB, packaged for local Docker Compose, CI/CD via Jenkins, GitOps releases through ArgoCD, and AWS-hosted Kubernetes managed with Terraform.

## Architecture

- ![Complete portfolio architecture](images/Complete Architercture.png) — End-to-end view of app tiers, CI/CD, GitOps, and cloud resources.
- ![Jenkins pipeline](images/Pipeline.png) — Build/test/publish/deploy stages run by Jenkins.
- ![Cluster architecture](images/Cluster.png) — AWS EKS cluster layout, node groups, and supporting services.
- ![Monitoring stack](images/monitoring.png) — Prometheus, Grafana, ELK, and alerting flows.
- ![Docker Compose microservices](images/Microservices.png) — Local development topology for backend, frontend, and MongoDB.

## Repository Map

| Area | Path | Highlights |
| --- | --- | --- |
| Backend API | `app/` | FastAPI, Pydantic models, workout planner, MongoDB access, structured logging |
| Frontend SPA | `frontend/` | React + Vite UI, auth flows, workout dashboards, NGINX reverse proxy |
| Infrastructure as Code | `infra/` | Terraform modules for VPC, EKS, IAM, storage, optional ArgoCD |
| Kubernetes Manifests | `k8s/` | Helm charts (`workout-app`, `workout-frontend`, umbrella `workout-stack`) |
| GitOps | `argocd/` | App-of-Apps parents, application sets, logging stack, SealedSecrets |
| Automation Scripts | `scripts/` | Integration and end-to-end flows against docker-compose stack |
| Testing | `tests/` | Pytest suite for planner/services logic |
| Visuals | `images/` | Architecture, pipeline, monitoring, and docker-compose diagrams |

## Component Highlights

### Backend (`app/`)
- Auth with PBKDF2 hashing and Mongo-backed sessions.
- Plan generation, workout completion logging, weekly summaries, and history filters.
- Request/response observability via `app/middleware.py` and business metrics logger.

### Frontend (`frontend/`)
- Hash-based routing, client-side auth persistence, workout creation and tracking UI.
- Shared JSON fetcher handles token management and error routing.
- Built with Vite, tested with Vitest, served behind NGINX proxy.

## Local Development

1. Copy `env-example` to `.env` and set `MONGO_URI`, `MONGO_DB_NAME`.
2. Start services: `docker compose up --build`.
3. Visit `http://localhost` for the SPA, `http://localhost/docs` for API docs, `http://localhost/health` for health checks.
4. Run unit tests: `docker build -f Dockerfile.test -t backend-test . && docker run --rm backend-test`.

## Deployment Flow

- Jenkins pipeline (see `Jenkinsfile`) builds test image, runs unit/integration/E2E checks, packages backend + frontend, pushes versioned tags to ECR, and bumps downstream Helm chart refs.
- ![Jenkins pipeline](images/Pipeline.png) provides the stage breakdown and artifact hand-offs.

## Kubernetes & GitOps

- Helm chart `k8s/charts/workout-stack` deploys backend, frontend, Mongo dependencies, and configures probes/resources.
- ArgoCD App-of-Apps (`argocd/*-parent.yaml`) sync infrastructure, applications, and logging stacks with automated prune/self-heal.

## Infrastructure as Code

- `infra/` Terraform provisions VPC, subnets, security, EKS, and EBS CSI driver.
- Requires Terraform 1.5+, AWS CLI, configured credentials. Standard flow:

  ```bash
  cd infra/main
  terraform init
  terraform apply
  aws eks update-kubeconfig --name workout-eks-cluster --region ap-south-1
