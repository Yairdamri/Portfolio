Working version notification post stage

Commands to know 
helm install [RELEASE_NAME] oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack



portf-forward

grafana
kubectl -n monitoring port-forward svc/prometheus-stack-grafana 3000:80

promethues
kubectl -n monitoring port-forward svc/prometheus-stack-kube-prom-prometheus 9090:9090



dashboard premetues

CPU Utilization per Node (%)




to destroy 
cd infra/environments/dev
terraform state list | grep -E 'kubernetes|helm_release'
terraform state rm 'module.argocd[0].kubernetes_namespace.this'
terraform state rm 'module.argocd[0].helm_release.argocd'
terraform state rm 'module.ebs_csi[0].kubernetes_storage_class_v1.default[0]'
terraform state rm 'module.eks_auth[0].kubernetes_config_map_v1_data.aws_auth[0]'
terraform destroy




to apply
1.terraform apply -target=module.network \
                 -target=module.security \
                 -target=module.eks \
                 -target=module.ebs_csi

2. terraform apply -target=module.argocd


Grafana pass 123456
