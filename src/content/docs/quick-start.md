---
title: Quick Start Guide
description: Get up and running with OSS Tools Portal in minutes
---

# Quick Start Guide

Welcome to OSS Tools Portal! This guide will help you set up a complete Kubernetes development environment with monitoring and CI/CD in just a few minutes.

## Prerequisites

Before starting, ensure you have the following tools installed:

- **Docker** - Container runtime
- **kind** - Kubernetes in Docker (for local clusters)
- **kubectl** - Kubernetes command-line tool
- **helm** - Kubernetes package manager
- **make** - Build automation tool

### Installation Links

- [Docker Installation](https://docs.docker.com/get-docker/)
- [kind Installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl Installation](https://kubernetes.io/docs/tasks/tools/)
- [Helm Installation](https://helm.sh/docs/intro/install/)

## One-Command Demo

The fastest way to see OSS Tools Portal in action:

```bash
git clone https://github.com/flexydox/flexydox.github.io.git
cd flexydox.github.io
make demo
```

This single command will:

1. ✅ Create a local Kubernetes cluster with kind
2. ✅ Install NGINX Ingress Controller
3. ✅ Deploy the complete Grafana Stack (Prometheus, Grafana, Loki)
4. ✅ Set up a sample application with monitoring
5. ✅ Configure port forwarding for easy access
6. ✅ Provide access URLs and next steps

## What You Get

After running `make demo`, you'll have:

### 📊 Monitoring Stack
- **Grafana** at http://localhost:3000 (admin/admin123)
- **Prometheus** for metrics collection
- **Loki** for log aggregation
- Pre-configured dashboards for cluster monitoring

### 🚀 Sample Application
- Nginx-based demo app with ingress
- Automatically monitored and logged
- Example of best practices

### 🔧 Development Environment
- 3-node Kubernetes cluster (1 control plane, 2 workers)
- Ingress controller for external access
- Proper namespace organization

## Next Steps

Once your demo environment is running:

1. **Explore Grafana Dashboards**
   ```bash
   open http://localhost:3000
   ```

2. **Check Cluster Status**
   ```bash
   make status
   ```

3. **View Application Logs**
   ```bash
   make logs
   ```

4. **Scale Your Application**
   ```bash
   kubectl scale deployment sample-app --replicas=5 -n oss-tools
   ```

## Customization

### Environment Variables

Customize your setup with environment variables:

```bash
# Custom cluster name
CLUSTER_NAME=my-cluster make demo

# Custom namespace
NAMESPACE=my-namespace make demo

# Custom Grafana password
GRAFANA_PASSWORD=mypassword make demo
```

### Configuration Files

Edit the configuration files in `infrastructure/` to customize:

- `infrastructure/scripts/demo.sh` - Main demo script
- `infrastructure/helm/grafana-stack/values.yaml` - Grafana Stack configuration
- `Makefile` - Available commands and shortcuts

## Cleanup

When you're done experimenting:

```bash
make clean
```

This will:
- Delete the Kubernetes cluster
- Stop all port forwarding
- Clean up Docker containers

## Troubleshooting

### Common Issues

**Docker not running:**
```bash
# Start Docker Desktop or daemon
sudo systemctl start docker  # Linux
# Or start Docker Desktop app
```

**Port conflicts:**
```bash
# Check what's using port 3000
lsof -i :3000
# Kill conflicting processes
pkill -f "port-forward"
```

**Cluster creation fails:**
```bash
# Clean up any existing clusters
kind delete cluster --name oss-tools-demo
# Try again
make demo
```

## Support

- 📚 [Full Documentation](/docs/)
- 🐛 [Report Issues](https://github.com/flexydox/flexydox.github.io/issues)
- 💬 [Discussions](https://github.com/flexydox/flexydox.github.io/discussions)
- 📧 [Community Support](mailto:support@oss-tools-portal.com)

---

Ready to dive deeper? Check out our guides for [Kubernetes Setup](/docs/kubernetes/), [Grafana Configuration](/docs/grafana/), and [CI/CD Templates](/docs/cicd/).