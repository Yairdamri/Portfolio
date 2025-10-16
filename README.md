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

## Sealed Secrets Management

### Passwords
- ArgoCD admin: 123456yair
- MongoDB password: workoutpass123

### How Sealed Secrets Work

The cluster uses **Sealed Secrets** to store encrypted credentials in Git safely. The master key is automatically restored from AWS Secrets Manager when the cluster is created.

**Master Key Location:** `arn:aws:secretsmanager:ap-south-1:273809175099:secret:sealed-secrets/master-key-EZiG8B`

### Workflow:
1. Terraform restores the sealing key from AWS Secrets Manager
2. ArgoCD deploys Sealed Secrets controller (uses the restored key)
3. ArgoCD syncs sealed secrets from GitLab
4. Sealed Secrets controller decrypts them automatically
5. Applications use the unsealed secrets

### Benefits:
- ✅ **No re-sealing needed** when recreating clusters
- ✅ **Secrets stay in Git** and work across cluster recreations
- ✅ **Fully automated** during terraform apply

### If Master Key is Lost:
If you need to re-seal secrets with a new key:
```bash
cd infra/main
kubeseal --fetch-cert > sealing-cert.pem

# Re-seal MongoDB secrets
kubectl create secret generic mongodb-user-credentials \
  --from-literal=password="workoutpass123" \
  --namespace=workout --dry-run=client -o yaml | \
kubeseal --cert sealing-cert.pem --format yaml \
  > ../../argocd/manifests/mongodb/mongodb-user-credentials-sealed.yaml

kubectl create secret generic mongodb-uri \
  --from-literal=MONGO_URI="mongodb://workout:workoutpass123@mongodb-replica-set-svc.workout.svc.cluster.local:27017/workout?authSource=admin&replicaSet=mongodb-replica-set" \
  --namespace=workout --dry-run=client -o yaml | \
kubeseal --cert sealing-cert.pem --format yaml \
  > ../../argocd/manifests/mongodb/mongodb-uri-sealed-secret.yaml

# Push to GitLab
cd ../../argocd
git add manifests/mongodb/
git commit -m "Re-seal secrets"
git push
```
