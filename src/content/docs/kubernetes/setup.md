---
title: Kubernetes Environment Setup
description: Complete guide to setting up Kubernetes clusters with OSS Tools Portal
---

# Kubernetes Environment Setup

OSS Tools Portal supports multiple Kubernetes deployment scenarios, from local development to cloud production environments.

## Local Development with kind

### Basic Setup

Create a simple cluster for development:

```bash
# Create basic cluster
kind create cluster --name dev-cluster

# Verify cluster
kubectl cluster-info --context kind-dev-cluster
```

### Multi-Node Setup

For more realistic testing, create a multi-node cluster:

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
kind create cluster --config kind-config.yaml --name multi-node
```

## Cloud Providers

### Amazon EKS

#### Prerequisites
```bash
# Install AWS CLI and eksctl
aws configure
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

#### Create EKS Cluster
```bash
# Basic EKS cluster
eksctl create cluster \
  --name oss-tools-cluster \
  --region us-west-2 \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --node-type t3.medium
```

#### Advanced EKS Configuration
```yaml
# eks-cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: oss-tools-cluster
  region: us-west-2

nodeGroups:
  - name: worker-nodes
    instanceType: t3.medium
    desiredCapacity: 3
    minSize: 1
    maxSize: 5
    volumeSize: 20
    ssh:
      allow: true
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        certManager: true
        efs: true
        ebs: true
        fsx: true
        cloudWatch: true

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver
```

```bash
eksctl create cluster -f eks-cluster.yaml
```

### Azure AKS

#### Prerequisites
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
```

#### Create AKS Cluster
```bash
# Create resource group
az group create --name oss-tools-rg --location eastus

# Create AKS cluster
az aks create \
  --resource-group oss-tools-rg \
  --name oss-tools-cluster \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group oss-tools-rg --name oss-tools-cluster
```

### Google GKE

#### Prerequisites
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

#### Create GKE Cluster
```bash
# Enable required APIs
gcloud services enable container.googleapis.com

# Create cluster
gcloud container clusters create oss-tools-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 5

# Get credentials
gcloud container clusters get-credentials oss-tools-cluster --zone us-central1-a
```

## k3s for Lightweight Deployments

### Single Node Setup
```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Copy kubeconfig for kubectl
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

### Multi-Node k3s Cluster
```bash
# On master node
curl -sfL https://get.k3s.io | sh -s - --node-token YOUR_TOKEN

# Get node token
sudo cat /var/lib/rancher/k3s/server/node-token

# On worker nodes
curl -sfL https://get.k3s.io | K3S_URL=https://MASTER_IP:6443 K3S_TOKEN=YOUR_TOKEN sh -
```

## Cluster Configuration

### Ingress Controller Setup

#### NGINX Ingress
```bash
# For kind clusters
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# For cloud providers
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Wait for deployment
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

#### Traefik (for k3s)
```yaml
# traefik-values.yaml
service:
  type: LoadBalancer
ports:
  web:
    port: 80
  websecure:
    port: 443
```

```bash
helm repo add traefik https://helm.traefik.io/traefik
helm install traefik traefik/traefik -f traefik-values.yaml
```

### Storage Classes

#### Local Storage (Development)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

#### Cloud Storage
```bash
# AWS EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

# Azure Disk CSI Driver (usually pre-installed in AKS)
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/install-driver.sh

# GCE Persistent Disk CSI Driver (usually pre-installed in GKE)
```

## Security Configuration

### RBAC Setup
```yaml
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: oss-tools-sa
  namespace: oss-tools
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: oss-tools-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oss-tools-binding
subjects:
- kind: ServiceAccount
  name: oss-tools-sa
  namespace: oss-tools
roleRef:
  kind: ClusterRole
  name: oss-tools-role
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies
```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: oss-tools-netpol
  namespace: oss-tools
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
```

## Monitoring Integration

Deploy monitoring alongside your cluster:

```bash
# Add OSS Tools Portal monitoring
helm repo add oss-tools https://flexydox.github.io/helm-charts
helm install monitoring oss-tools/grafana-stack -n oss-tools
```

## Troubleshooting

### Common Issues

**Cluster Not Responding:**
```bash
# Check cluster status
kubectl cluster-info dump

# Restart kubelet (for VMs)
sudo systemctl restart kubelet
```

**DNS Issues:**
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

**Storage Issues:**
```bash
# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv,pvc --all-namespaces
```

## Next Steps

- [Install Grafana Stack monitoring](/docs/grafana/)
- [Set up CI/CD pipelines](/docs/cicd/)
- [Configure GitHub Actions runners](/docs/cicd/github-runners/)
- [Explore deployment recipes](/docs/recipes/)