---
title: Nastavení Kubernetes prostředí
description: Kompletní průvodce nastavením Kubernetes clusterů s Flexydox
---

# Nastavení Kubernetes prostředí

Flexydox podporuje více scénářů nasazení Kubernetes, od lokálního vývoje až po cloudová produkční prostředí.

## Lokální vývoj s kind

### Základní nastavení

Vytvořte jednoduchý cluster pro vývoj:

```bash
# Vytvoření základního clusteru
kind create cluster --name dev-cluster

# Ověření clusteru
kubectl cluster-info --context kind-dev-cluster
```

### Multi-Node nastavení

Pro realističtější testování vytvořte multi-node cluster:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
- role: worker
```

```bash
# Vytvoření clusteru s konfigurací
kind create cluster --name flexydox-multi --config kind-config.yaml
```

## Cloud Kubernetes (AKS, EKS, GKE)

### Azure Kubernetes Service (AKS)

```bash
# Vytvoření resource group
az group create --name flexydox-rg --location eastus

# Vytvoření AKS clusteru
az aks create \
  --resource-group flexydox-rg \
  --name flexydox-cluster \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Získání credentials
az aks get-credentials --resource-group flexydox-rg --name flexydox-cluster
```

### Amazon EKS

```bash
# Vytvoření EKS clusteru pomocí eksctl
eksctl create cluster \
  --name flexydox-cluster \
  --version 1.28 \
  --region us-west-2 \
  --nodegroup-name workers \
  --node-type m5.large \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 5 \
  --managed
```

### Google Kubernetes Engine (GKE)

```bash
# Vytvoření GKE clusteru
gcloud container clusters create flexydox-cluster \
  --zone us-central1-a \
  --machine-type e2-standard-2 \
  --num-nodes 3 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 5 \
  --enable-autorepair \
  --enable-autoupgrade

# Získání credentials
gcloud container clusters get-credentials flexydox-cluster --zone us-central1-a
```

## Instalace základních komponent

### NGINX Ingress Controller

```bash
# Pro kind
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Čekání na připravenost
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### MetalLB (pro kind)

```bash
# Instalace MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

# Konfigurace IP pool
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
  - 172.19.255.200-172.19.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF
```

## Grafana Stack nasazení

### Pomocí Helm

```bash
# Přidání Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Instalace Grafana Stack
helm install monitoring grafana/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values.yaml
```

### Vlastní konfigurace

```yaml
# values.yaml
grafana:
  adminPassword: "admin123"
  ingress:
    enabled: true
    hosts:
      - grafana.local
  persistence:
    enabled: true
    size: 10Gi

prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: fast
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

alertmanager:
  ingress:
    enabled: true
    hosts:
      - alertmanager.local
```

## Konfigurace pro různá prostředí

### Development

```yaml
# dev-values.yaml
grafana:
  resources:
    requests:
      memory: 128Mi
      cpu: 100m
    limits:
      memory: 256Mi
      cpu: 200m

prometheus:
  prometheusSpec:
    retention: 7d
    resources:
      requests:
        memory: 512Mi
        cpu: 200m
```

### Staging

```yaml
# staging-values.yaml
grafana:
  replicas: 2
  resources:
    requests:
      memory: 256Mi
      cpu: 200m
    limits:
      memory: 512Mi
      cpu: 500m

prometheus:
  prometheusSpec:
    retention: 15d
    replicas: 2
    resources:
      requests:
        memory: 2Gi
        cpu: 500m
```

### Production

```yaml
# prod-values.yaml
grafana:
  replicas: 3
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 1Gi
      cpu: 1000m
  persistence:
    size: 50Gi
    storageClass: fast-ssd

prometheus:
  prometheusSpec:
    retention: 90d
    replicas: 3
    resources:
      requests:
        memory: 8Gi
        cpu: 2000m
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: fast-ssd
          resources:
            requests:
              storage: 200Gi
```

## Bezpečnostní konfigurace

### RBAC Setup

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flexydox-sa
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: flexydox-role
rules:
- apiGroups: [""]
  resources: ["nodes", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: flexydox-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flexydox-role
subjects:
- kind: ServiceAccount
  name: flexydox-sa
  namespace: monitoring
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-network-policy
  namespace: monitoring
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  egress:
  - {}
```

## Monitoring a troubleshooting

### Užitečné příkazy

```bash
# Kontrola stavu clusteru
kubectl get nodes
kubectl get pods -A

# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Prometheus logs  
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Port forwarding pro local access
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

### Běžné problémy

**1. Pods v Pending stavu**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl get events --sort-by=.metadata.creationTimestamp
```

**2. Ingress nefunguje**
```bash
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>
```

**3. Storage problémy**
```bash
kubectl get pv,pvc -A
kubectl describe pvc <pvc-name> -n <namespace>
```

## Další kroky

- [Grafana konfigurace](/cs/docs/grafana/setup/)
- [CI/CD nastavení](/cs/docs/cicd/github-actions/)
- [Scaling recepty](/cs/docs/recipes/scaling-clusters/)

Váš Kubernetes cluster je nyní připraven pro produkční nasazení s kompletním monitoringem! 🚀