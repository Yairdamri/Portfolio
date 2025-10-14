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
aws eks update-kubeconfig --name dev-workout-eks --region ap-south-1  
aws eks update-nodegroup-config \                                     
  --cluster-name dev-workout-eks \
  --nodegroup-name default-20251013150031631900000013 \
  --scaling-config minSize=3,maxSize=3,desiredSize=3
terraform apply -var-file=terraform.tfvars -var deploy_k8s_addons=true -target=module.argocd

.
..



to destroy 
cd infra/environments/dev
terraform state list | grep -E 'kubernetes|helm_release'
terraform state rm 'module.argocd[0].kubernetes_namespace.this'
terraform state rm 'module.argocd[0].helm_release.argocd'
terraform state rm 'module.ebs_csi[0].kubernetes_storage_class_v1.default[0]'
terraform state rm 'module.eks_auth[0].kubernetes_config_map_v1_data.aws_auth[0]'
terraform destroy
