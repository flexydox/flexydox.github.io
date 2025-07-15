#!/bin/bash
set -euo pipefail

# OSS Tools Portal - One Command Demo
# This script sets up a complete Kubernetes development environment with monitoring and CI/CD

CLUSTER_NAME="${CLUSTER_NAME:-oss-tools-demo}"
NAMESPACE="${NAMESPACE:-oss-tools}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin123}"

echo "🚀 Starting OSS Tools Portal Demo Setup..."
echo "   Cluster: $CLUSTER_NAME"
echo "   Namespace: $NAMESPACE"
echo ""

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    local missing_tools=()
    
    command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
    command -v kind >/dev/null 2>&1 || missing_tools+=("kind")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v helm >/dev/null 2>&1 || missing_tools+=("helm")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "❌ Missing required tools: ${missing_tools[*]}"
        echo "   Please install them and try again."
        echo ""
        echo "   Installation guides:"
        echo "   - Docker: https://docs.docker.com/get-docker/"
        echo "   - kind: https://kind.sigs.k8s.io/docs/user/quick-start/"
        echo "   - kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "   - helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    
    echo "✅ All prerequisites satisfied"
}

# Create kind cluster
create_cluster() {
    echo "🏗️  Creating Kubernetes cluster with kind..."
    
    if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
        echo "   Cluster '$CLUSTER_NAME' already exists, deleting..."
        kind delete cluster --name "$CLUSTER_NAME"
    fi
    
    cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
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
  - containerPort: 3000
    hostPort: 3000
    protocol: TCP
- role: worker
- role: worker
EOF
    
    echo "✅ Cluster created successfully"
}

# Install ingress controller
install_ingress() {
    echo "🌐 Installing NGINX Ingress Controller..."
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    echo "   Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    
    echo "✅ Ingress controller ready"
}

# Create namespace
setup_namespace() {
    echo "📦 Setting up namespace..."
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    kubectl config set-context --current --namespace="$NAMESPACE"
    
    echo "✅ Namespace '$NAMESPACE' ready"
}

# Install Grafana Stack
install_grafana_stack() {
    echo "📊 Installing Grafana Stack (Prometheus, Grafana, Loki)..."
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install kube-prometheus-stack
    echo "   Installing Prometheus and Grafana..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        --set grafana.adminPassword="$GRAFANA_PASSWORD" \
        --set grafana.service.type=NodePort \
        --set grafana.service.nodePort=32000 \
        --set grafana.ingress.enabled=true \
        --set grafana.ingress.ingressClassName=nginx \
        --set grafana.ingress.hosts[0]=grafana.local \
        --set prometheus.service.type=NodePort \
        --set prometheus.service.nodePort=32001 \
        --wait --timeout=300s
    
    # Install Loki
    echo "   Installing Loki..."
    helm upgrade --install loki grafana/loki-stack \
        --namespace "$NAMESPACE" \
        --set grafana.enabled=false \
        --set prometheus.enabled=false \
        --set promtail.enabled=true \
        --wait --timeout=300s
    
    echo "✅ Grafana Stack installed"
}

# Deploy sample application
deploy_sample_app() {
    echo "🚀 Deploying sample application..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: $NAMESPACE
  labels:
    app: sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: $NAMESPACE
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
EOF
    
    echo "✅ Sample application deployed"
}

# Setup GitHub runners (placeholder)
setup_github_runners() {
    echo "🏃 Setting up GitHub Actions runners..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: runner-config
  namespace: $NAMESPACE
data:
  setup.md: |
    # GitHub Actions Self-Hosted Runners
    
    To set up self-hosted GitHub Actions runners in this cluster:
    
    1. Create a GitHub Personal Access Token with 'repo' scope
    2. Install actions-runner-controller:
       helm install actions-runner-controller actions-runner-controller/actions-runner-controller
    3. Configure runner deployment with your repository details
    
    For detailed instructions, visit:
    https://github.com/actions-runner-controller/actions-runner-controller
EOF
    
    echo "✅ GitHub runners configuration ready"
}

# Print access information
print_access_info() {
    echo ""
    echo "🎉 OSS Tools Portal Demo is ready!"
    echo ""
    echo "📊 Access your services:"
    echo "   Grafana:    http://localhost:3000 (admin / $GRAFANA_PASSWORD)"
    echo "   Prometheus: http://localhost:9090"
    echo "   Sample App: http://app.local:8080 (add '127.0.0.1 app.local' to /etc/hosts)"
    echo ""
    echo "🔧 Useful commands:"
    echo "   kubectl get pods -n $NAMESPACE"
    echo "   kubectl logs -f deployment/sample-app -n $NAMESPACE"
    echo "   kind delete cluster --name $CLUSTER_NAME"
    echo ""
    echo "📚 Next steps:"
    echo "   - Visit http://localhost:3000 to explore Grafana dashboards"
    echo "   - Check out the documentation at /docs/"
    echo "   - Explore more recipes and templates"
    echo ""
}

# Port forwarding
setup_port_forwarding() {
    echo "🔌 Setting up port forwarding..."
    
    # Kill any existing port-forward processes
    pkill -f "kubectl.*port-forward" || true
    
    # Forward Grafana
    kubectl port-forward -n "$NAMESPACE" svc/prometheus-grafana 3000:80 &
    
    # Forward Prometheus (optional)
    # kubectl port-forward -n "$NAMESPACE" svc/prometheus-kube-prometheus-prometheus 9090:9090 &
    
    sleep 2
    echo "✅ Port forwarding configured"
}

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    pkill -f "kubectl.*port-forward" || true
    echo "   Port forwarding stopped"
}

# Trap cleanup
trap cleanup EXIT

# Main execution
main() {
    check_prerequisites
    create_cluster
    install_ingress
    setup_namespace
    install_grafana_stack
    deploy_sample_app
    setup_github_runners
    setup_port_forwarding
    print_access_info
    
    # Keep script running for port forwarding
    echo "🔄 Keeping port forwarding active... (Press Ctrl+C to stop)"
    wait
}

# Run only if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi