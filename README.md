Working version notification post stage

Commands to know 
helm install [RELEASE_NAME] oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack

terraform apply -target=module.network \
                -target=module.eks \
                -target=module.eks_auth \
                -target=module.ebs_csi \
                -target=module.argocd.helm_release.argocd \
                -target=module.argocd.kubernetes_namespace.this

terraform apply -target=module.argocd.kubernetes_namespace.this -target=module.argocd.helm_release.argocd


terraform apply -target=module.argocd.kubernetes_namespace.this -target=module.argocd.helm_release.argocd


During operations like scaling the node group, run Terraform with those modules disabled:
terraform apply -var-file=terraform.tfvars -var deploy_k8s_addons=false

Whenever you need to deploy or update the Kubernetes extras again, re-enable the flag:
terraform apply -var-file=terraform.tfvars -var deploy_k8s_addons=true



the things i do when i deploy the cluster
adding repos to the argocd
applying the infra app and the app of app


to apply terraform 

1. terraform apply -target=module.network \
                -target=module.eks \
                -target=module.eks_auth \
                -target=module.ebs_csi \
                -target=module.argocd.helm_release.argocd \
                -target=module.argocd.kubernetes_namespace.this

2. terraform apply -var-file=terraform.tfvars -var deploy_k8s_addons=true -target=module.argocd




portf-forward

grafana
kubectl -n monitoring port-forward svc/prometheus-stack-grafana 3000:80

promethues
kubectl -n monitoring port-forward svc/prometheus-stack-kube-prom-prometheus 9090:9090



dashboard premetues

CPU Utilization per Node (%)


to apply terraform 
terraform apply -var-file=terraform.tfvars -var deploy_k8s_addons=false
terraform apply -var-file=terraform.tfvars -var deploy_k8s_addons=true -target=module.argocd
