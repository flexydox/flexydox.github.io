# OSS Tools Portal

[![Deploy to GitHub Pages](https://github.com/flexydox/flexydox.github.io/actions/workflows/deploy.yml/badge.svg)](https://github.com/flexydox/flexydox.github.io/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Comprehensive toolkit for small-to-medium IT departments to instantly spin up Kubernetes environments with monitoring, CI/CD, and automated deployments.**

## 🚀 Quick Start

Get a complete Kubernetes development environment with monitoring and CI/CD in under 10 minutes:

```bash
git clone https://github.com/flexydox/flexydox.github.io.git
cd flexydox.github.io
make demo
```

This single command will:
- ✅ Create a local Kubernetes cluster with kind
- ✅ Install NGINX Ingress Controller  
- ✅ Deploy complete Grafana Stack (Prometheus, Grafana, Loki)
- ✅ Set up sample application with monitoring
- ✅ Configure port forwarding and access

Access your services:
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Sample App**: http://app.local:8080 (add to `/etc/hosts`)

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [helm](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- [make](https://www.gnu.org/software/make/) - Build automation

## 🎯 What You Get

### 📊 Complete Monitoring Stack
- **Prometheus** for metrics collection and alerting
- **Grafana** for visualization and dashboards  
- **Loki** for log aggregation and analysis
- **Promtail** for log shipping
- Pre-configured dashboards for cluster and application monitoring

### 🏗️ Infrastructure as Code
- **Helm charts** for all components
- **Configuration templates** for different environments
- **Automated deployment scripts** for cloud providers
- **Best practices** baked into every template

### 🔄 CI/CD Ready
- **GitHub Actions workflows** for building and deploying
- **Self-hosted runners** in Kubernetes
- **Multi-environment** deployment patterns
- **Security scanning** and compliance checks

### 📚 Comprehensive Documentation
- **Step-by-step guides** for all components
- **Real-world recipes** for common scenarios
- **Troubleshooting guides** and best practices
- **API reference** and configuration examples

## 🛠️ Available Commands

| Command | Description |
|---------|-------------|
| `make demo` | 🚀 Start complete demo environment |
| `make status` | 📋 Show cluster and deployment status |
| `make logs` | 📝 Show application logs |
| `make clean` | 🧹 Clean up demo environment |
| `make build` | 🏗️ Build the documentation site |
| `make dev` | 🔥 Start development server |

## 📖 Documentation

Visit [https://flexydox.github.io](https://flexydox.github.io) for complete documentation, or explore locally:

```bash
npm run dev
# Visit http://localhost:4321
```

### Key Sections

- **[Quick Start](/docs/quick-start/)** - Get up and running in minutes
- **[Kubernetes Setup](/docs/kubernetes/)** - Cluster configuration for all environments
- **[Grafana Stack](/docs/grafana/)** - Complete monitoring and observability
- **[CI/CD Templates](/docs/cicd/)** - Production-ready automation workflows
- **[Recipes](/docs/recipes/)** - Real-world patterns and solutions

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Development    │    │     Staging     │    │   Production    │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │    kind     │ │    │ │   AKS/EKS   │ │    │ │   AKS/EKS   │ │
│ │   cluster   │ │    │ │   cluster   │ │    │ │   cluster   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Grafana   │ │    │ │   Grafana   │ │    │ │   Grafana   │ │
│ │    Stack    │ │    │ │    Stack    │ │    │ │    Stack    │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  GitHub Actions │
                    │     CI/CD       │
                    └─────────────────┘
```

## 🔧 Infrastructure Components

### `/infrastructure/`
```
infrastructure/
├── scripts/
│   ├── demo.sh              # One-command demo setup
│   ├── cluster-setup.sh     # Kubernetes cluster creation
│   └── grafana-setup.sh     # Monitoring stack deployment
├── helm/
│   ├── grafana-stack/       # Complete monitoring helm chart
│   └── actions-runner/      # GitHub Actions runners
└── examples/
    └── workflows/           # CI/CD pipeline templates
```

### Helm Charts

#### Grafana Stack (`infrastructure/helm/grafana-stack/`)
- Prometheus with custom recording rules
- Grafana with pre-configured dashboards
- Loki for centralized logging
- Alert manager with notification channels

#### GitHub Actions Runners (`infrastructure/helm/actions-runner/`)
- Self-hosted runners in Kubernetes
- Auto-scaling based on job queue
- Secure runner registration

## 🌟 Features

### ⚡ Lightning Fast Setup
- **One-command deployment** with `make demo`
- **Pre-configured templates** for all components
- **Automated dependency management** with Helm
- **Zero-config monitoring** out of the box

### 🔒 Security First
- **Network policies** for pod-to-pod communication
- **RBAC** configurations for all components
- **Secret management** best practices
- **Security scanning** in CI/CD pipelines

### 📈 Production Ready
- **High availability** configurations
- **Resource optimization** and auto-scaling
- **Backup and disaster recovery** procedures
- **Multi-region deployment** patterns

### 🎛️ Fully Customizable
- **Environment-specific** configurations
- **Extensible** monitoring and alerting
- **Custom dashboards** and metrics
- **Pluggable** CI/CD workflows

## 🚀 Deployment Options

### Local Development
```bash
# Single command setup
make demo

# Custom configuration
CLUSTER_NAME=my-dev NAMESPACE=development make demo
```

### Cloud Providers

#### AWS EKS
```bash
# Create EKS cluster
eksctl create cluster -f infrastructure/examples/eks-cluster.yaml

# Deploy monitoring stack
helm install grafana-stack ./infrastructure/helm/grafana-stack
```

#### Azure AKS
```bash
# Create AKS cluster
az aks create --resource-group myRG --name myCluster --node-count 3

# Deploy stack
helm install grafana-stack ./infrastructure/helm/grafana-stack
```

#### Google GKE
```bash
# Create GKE cluster
gcloud container clusters create my-cluster --num-nodes=3

# Deploy stack
helm install grafana-stack ./infrastructure/helm/grafana-stack
```

## 📊 Monitoring and Observability

### Pre-configured Dashboards
- **Kubernetes Cluster Overview** - Resource usage, node status, pod health
- **Application Metrics** - Request rates, response times, error rates
- **Infrastructure Monitoring** - CPU, memory, disk, network
- **CI/CD Pipeline Metrics** - Build times, success rates, deployment frequency

### Alerting Rules
- **Critical alerts** for cluster health issues
- **Warning alerts** for resource constraints
- **Custom alerts** for application-specific metrics
- **Integration** with Slack, email, PagerDuty

### Log Management
- **Centralized logging** with Loki
- **Structured log parsing** with Promtail
- **Log-based alerting** and metrics
- **Long-term retention** strategies

## 🔄 CI/CD Integration

### GitHub Actions Templates
- **Multi-stage pipelines** (build, test, security scan, deploy)
- **Matrix builds** for multiple environments
- **Artifact management** and caching
- **Automated releases** and rollbacks

### Self-Hosted Runners
- **Kubernetes-native** GitHub Actions runners
- **Auto-scaling** based on job queue length
- **Secure** runner registration and management
- **Custom runner images** with pre-installed tools

## 🧪 Testing and Quality

### Automated Testing
```bash
# Run all tests
make test

# Integration tests
make test-integration

# Performance tests
make test-performance
```

### Quality Gates
- **Code coverage** reporting
- **Security vulnerability** scanning
- **Container image** security analysis
- **Kubernetes manifest** validation

## 📈 Performance and Scaling

### Auto-scaling
- **Horizontal Pod Autoscaler** configurations
- **Vertical Pod Autoscaler** for right-sizing
- **Cluster autoscaler** for node management
- **Custom metrics** scaling

### Resource Optimization
- **Resource requests and limits** best practices
- **Quality of Service** class configurations
- **Node affinity** and pod anti-affinity rules
- **Cost optimization** strategies

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
```bash
# Clone the repository
git clone https://github.com/flexydox/flexydox.github.io.git
cd flexydox.github.io

# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test
```

### Contribution Areas
- 📚 **Documentation** improvements and new guides
- 🔧 **Infrastructure** templates and configurations
- 🎨 **Dashboard** designs and monitoring improvements
- 🚀 **CI/CD** pipeline enhancements
- 🐛 **Bug fixes** and performance optimizations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📚 **Documentation**: [https://flexydox.github.io](https://flexydox.github.io)
- 🐛 **Issues**: [GitHub Issues](https://github.com/flexydox/flexydox.github.io/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/flexydox/flexydox.github.io/discussions)
- 📧 **Email**: [support@oss-tools-portal.com](mailto:support@oss-tools-portal.com)

## 🌟 Acknowledgments

- **Kubernetes** community for the amazing ecosystem
- **Grafana Labs** for the outstanding monitoring stack
- **Helm** community for package management
- **GitHub** for the powerful Actions platform
- All the **contributors** who make this project possible

---

**Ready to transform your DevOps workflow?** 🚀

```bash
git clone https://github.com/flexydox/flexydox.github.io.git
cd flexydox.github.io
make demo
```