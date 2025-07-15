---
title: Grafana Stack Setup
description: Complete monitoring and observability with Grafana, Prometheus, and Loki
---

# Grafana Stack Setup

The OSS Tools Portal includes a complete monitoring and observability stack built on Grafana, Prometheus, and Loki. This guide covers installation, configuration, and best practices.

## Overview

The Grafana Stack provides:

- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboarding
- **Loki** - Log aggregation and storage
- **Promtail** - Log shipping agent
- **AlertManager** - Alert routing and management

## Quick Installation

### Using OSS Tools Portal
```bash
# Deploy complete stack
make demo

# Or install just monitoring
helm install grafana-stack ./infrastructure/helm/grafana-stack -n oss-tools
```

### Manual Installation

#### Add Helm Repositories
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

#### Install Prometheus Stack
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword="admin123" \
  --set grafana.service.type=LoadBalancer
```

#### Install Loki Stack
```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.enabled=false \
  --set promtail.enabled=true
```

## Configuration

### Grafana Configuration

#### Custom Values File
```yaml
# grafana-values.yaml
adminPassword: "secure-password"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  ingressClassName: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - grafana.local
  paths:
    - /

# Enable persistence
persistence:
  enabled: true
  size: 10Gi
  storageClassName: standard

# Install plugins
plugins:
  - grafana-piechart-panel
  - grafana-worldmap-panel
  - grafana-clock-panel

# Configure data sources
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server:80
      access: proxy
      isDefault: true
    - name: Loki
      type: loki
      url: http://loki:3100
      access: proxy

# Configure dashboards
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default

dashboards:
  default:
    kubernetes-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    kubernetes-pods:
      gnetId: 6417
      revision: 1
      datasource: Prometheus
    node-exporter:
      gnetId: 1860
      revision: 27
      datasource: Prometheus
```

#### Apply Configuration
```bash
helm upgrade grafana prometheus-community/grafana \
  -f grafana-values.yaml \
  -n monitoring
```

### Prometheus Configuration

#### Custom Scrape Configs
```yaml
# prometheus-values.yaml
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
    - job_name: 'custom-app'
      static_configs:
      - targets: ['app-service:8080']
      metrics_path: /metrics
      scrape_interval: 30s
    
    # Storage retention
    retention: 15d
    retentionSize: "5GB"
    
    # Resource limits
    resources:
      requests:
        cpu: 200m
        memory: 400Mi
      limits:
        cpu: 1000m
        memory: 2Gi
    
    # Persistent storage
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: standard
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

# Configure AlertManager
alertmanager:
  config:
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'alerts@yourcompany.com'
    
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
    
    receivers:
    - name: 'web.hook'
      email_configs:
      - to: 'admin@yourcompany.com'
        subject: '[ALERT] {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
```

### Loki Configuration

#### Custom Configuration
```yaml
# loki-values.yaml
loki:
  config:
    auth_enabled: false
    
    server:
      http_listen_port: 3100
    
    ingester:
      lifecycler:
        address: 127.0.0.1
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
    
    schema_config:
      configs:
        - from: 2020-10-24
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h
    
    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/boltdb-shipper-active
        cache_location: /loki/boltdb-shipper-cache
        shared_store: filesystem
      filesystem:
        directory: /loki/chunks
    
    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h
    
    chunk_store_config:
      max_look_back_period: 0s
    
    table_manager:
      retention_deletes_enabled: true
      retention_period: 168h

# Promtail configuration
promtail:
  config:
    server:
      http_listen_port: 3101
    
    clients:
      - url: http://loki:3100/loki/api/v1/push
    
    scrape_configs:
    - job_name: kubernetes-pods
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
```

## Default Dashboards

OSS Tools Portal includes pre-configured dashboards:

### Kubernetes Cluster Overview
- Cluster resource usage
- Node status and metrics
- Pod resource consumption
- Network traffic

### Application Monitoring
- Request rates and latency
- Error rates and status codes
- Database connections
- Custom business metrics

### Infrastructure Monitoring
- CPU, memory, disk usage
- Network I/O
- Load averages
- System alerts

## Custom Dashboards

### Creating Application Dashboard
```json
{
  "dashboard": {
    "title": "Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "timeseries",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
```

### Importing via ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  app-dashboard.json: |
    # JSON dashboard content here
```

## Alerting Rules

### Kubernetes Alerts
```yaml
# alerts.yaml
groups:
- name: kubernetes
  rules:
  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod {{ $labels.pod }} is crash looping"
      description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"

  - alert: NodeNotReady
    expr: kube_node_status_condition{condition="Ready",status="true"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Node {{ $labels.node }} is not ready"
      description: "Node {{ $labels.node }} has been not ready for more than 5 minutes"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage on {{ $labels.instance }}"
      description: "Memory usage is above 90% on {{ $labels.instance }}"
```

### Application Alerts
```yaml
- name: application
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is above 10% for the last 5 minutes"

  - alert: SlowResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Slow response time detected"
      description: "95th percentile response time is above 1 second"
```

## Log Management

### Log Collection
```yaml
# Application logging configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-logging-config
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         1
        Log_Level     info
        Daemon        off
    
    [INPUT]
        Name              tail
        Path              /var/log/app/*.log
        Parser            json
        Tag               app.*
        Refresh_Interval  5
    
    [OUTPUT]
        Name  loki
        Match *
        Host  loki
        Port  3100
        Labels job=app
```

### Log Queries
```bash
# View application logs
{job="app"} |= "error"

# Filter by time range
{job="app"} |= "error" | json | level="ERROR"

# Aggregate log counts
count_over_time({job="app"}[5m])

# Error rate calculation
sum(rate({job="app"} |= "error" [5m])) / sum(rate({job="app"} [5m]))
```

## Performance Optimization

### Prometheus Tuning
```yaml
# High-performance configuration
prometheus:
  prometheusSpec:
    # Increase storage retention
    retention: 30d
    retentionSize: "50GB"
    
    # Optimize for high cardinality
    walCompression: true
    
    # Resource allocation
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
      limits:
        cpu: 2000m
        memory: 4Gi
    
    # Storage optimization
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: fast-ssd
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
```

### Grafana Performance
```yaml
grafana:
  # Database optimization
  persistence:
    enabled: true
    size: 50Gi
    storageClassName: fast-ssd
  
  # Resource allocation
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
  
  # Configuration optimization
  grafana.ini:
    database:
      wal: true
      cache_mode: shared
    server:
      enable_gzip: true
    explore:
      enabled: true
```

## Troubleshooting

### Common Issues

**Grafana Not Loading:**
```bash
# Check pod status
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Check logs
kubectl logs -f deployment/grafana -n monitoring

# Check service
kubectl get svc -n monitoring
```

**Missing Metrics:**
```bash
# Verify Prometheus targets
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
# Visit http://localhost:9090/targets

# Check ServiceMonitor
kubectl get servicemonitor -n monitoring
```

**Log Ingestion Issues:**
```bash
# Check Promtail pods
kubectl get pods -l app=promtail

# Check Promtail logs
kubectl logs -l app=promtail

# Verify Loki connection
kubectl port-forward svc/loki 3100:3100 -n monitoring
# Test: curl http://localhost:3100/ready
```

## Security Best Practices

### Access Control
```yaml
# Grafana RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: grafana-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
```

### Network Security
```yaml
# Network policy for monitoring namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-netpol
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
          name: ingress-nginx
  - from:
    - podSelector: {}
```

## Next Steps

- [Set up CI/CD monitoring](/docs/cicd/)
- [Configure application metrics](/docs/recipes/application-monitoring/)
- [Create custom dashboards](/docs/recipes/custom-dashboards/)
- [Set up alerting workflows](/docs/recipes/alerting/)