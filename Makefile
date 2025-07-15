# OSS Tools Portal - DevOps Toolkit Makefile

.PHONY: demo clean install build dev preview help

# Default target
.DEFAULT_GOAL := help

# Variables
CLUSTER_NAME ?= oss-tools-demo
NAMESPACE ?= oss-tools

## Demo Commands

demo: ## 🚀 Start the one-command demo (Kind cluster + Grafana Stack + Sample App)
	@echo "🎯 Starting OSS Tools Portal Demo..."
	./infrastructure/scripts/demo.sh

demo-clean: ## 🧹 Clean up demo environment
	@echo "🧹 Cleaning up demo environment..."
	-kind delete cluster --name $(CLUSTER_NAME)
	-pkill -f "kubectl.*port-forward" || true
	@echo "✅ Demo environment cleaned"

## Development Commands

install: ## 📦 Install dependencies
	npm install

build: ## 🏗️  Build the static site
	npm run build

dev: ## 🔥 Start development server
	npm run dev

preview: ## 👀 Preview built site
	npm run preview

check: ## ✅ Type check and lint
	npm run build

## Infrastructure Commands

cluster-create: ## 🏗️  Create Kubernetes cluster only
	./infrastructure/scripts/cluster-setup.sh

cluster-delete: ## 🗑️  Delete Kubernetes cluster
	kind delete cluster --name $(CLUSTER_NAME)

grafana-install: ## 📊 Install Grafana Stack only
	./infrastructure/scripts/grafana-setup.sh

runners-setup: ## 🏃 Set up GitHub Actions runners
	./infrastructure/scripts/runners-setup.sh

## Utility Commands

status: ## 📋 Show cluster and deployment status
	@echo "📊 Cluster Status:"
	@kubectl cluster-info --context kind-$(CLUSTER_NAME) 2>/dev/null || echo "❌ Cluster not running"
	@echo ""
	@echo "📦 Pods in $(NAMESPACE) namespace:"
	@kubectl get pods -n $(NAMESPACE) 2>/dev/null || echo "❌ Namespace not found"
	@echo ""
	@echo "🌐 Services:"
	@kubectl get svc -n $(NAMESPACE) 2>/dev/null || echo "❌ No services found"

logs: ## 📝 Show application logs
	kubectl logs -f deployment/sample-app -n $(NAMESPACE)

shell: ## 💻 Open shell in sample app pod
	kubectl exec -it deployment/sample-app -n $(NAMESPACE) -- /bin/sh

port-forward: ## 🔌 Set up port forwarding to services
	@echo "🔌 Setting up port forwarding..."
	kubectl port-forward -n $(NAMESPACE) svc/prometheus-grafana 3000:80 &
	@echo "✅ Grafana available at http://localhost:3000"

clean: demo-clean ## 🧹 Clean up everything
	@echo "🧹 Cleaning up all generated files..."
	rm -rf dist
	rm -rf node_modules
	@echo "✅ Cleanup complete"

## Documentation

docs-build: ## 📚 Build documentation
	@echo "📚 Building documentation..."
	npm run build
	@echo "✅ Documentation built to dist/"

docs-serve: ## 🌐 Serve documentation locally
	@echo "🌐 Serving documentation..."
	npm run preview

## Help

help: ## 📖 Show this help message
	@echo "OSS Tools Portal - DevOps Toolkit"
	@echo "================================="
	@echo ""
	@echo "Available commands:"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Quick start:"
	@echo "  make demo     # Start complete demo environment"
	@echo "  make status   # Check what's running"
	@echo "  make clean    # Clean up everything"
	@echo ""
	@echo "For more information, visit: https://flexydox.github.io/docs/"