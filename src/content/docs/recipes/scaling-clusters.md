---
title: Scaling Clusters
description: Best practices for scaling Kubernetes clusters with OSS Tools Portal
---

# Scaling Clusters

Learn how to effectively scale your Kubernetes clusters as your application grows, from single-node development to multi-region production deployments.

## Horizontal Scaling

### Node Scaling

#### Automatic Node Scaling (Cloud Providers)

**AWS EKS with Cluster Autoscaler:**
```yaml
# cluster-autoscaler.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  template:
    spec:
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.0
        name: cluster-autoscaler
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/eks-cluster-name
```

**Azure AKS Scaling:**
```bash
# Enable cluster autoscaler
az aks update \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 10

# Update autoscaler settings
az aks update \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --update-cluster-autoscaler \
  --min-count 2 \
  --max-count 15
```

**GKE Autoscaling:**
```bash
# Create cluster with autoscaling
gcloud container clusters create my-cluster \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 10 \
  --num-nodes 3

# Update existing cluster
gcloud container clusters update my-cluster \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 10
```

#### Manual Node Scaling

**kind (Development):**
```yaml
# kind-scale-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
- role: worker  # Add more workers
```

```bash
# Recreate cluster with more nodes
kind delete cluster --name dev-cluster
kind create cluster --config kind-scale-config.yaml --name dev-cluster
```

**k3s Scaling:**
```bash
# Add worker nodes to existing k3s cluster
# On new worker node:
curl -sfL https://get.k3s.io | K3S_URL=https://master-ip:6443 K3S_TOKEN=your-token sh -

# Verify nodes
kubectl get nodes
```

### Pod Scaling

#### Horizontal Pod Autoscaler (HPA)
```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 2
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

#### Custom Metrics HPA
```yaml
# custom-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-custom-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 3
  maxReplicas: 100
  metrics:
  - type: Object
    object:
      metric:
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: "30"
      describedObject:
        apiVersion: v1
        kind: Service
        name: sample-app
```

#### Vertical Pod Autoscaler (VPA)
```yaml
# vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2000m
        memory: 4Gi
      controlledResources: ["cpu", "memory"]
      controlledValues: RequestsAndLimits
```

## Vertical Scaling

### Resource Optimization

#### Right-sizing Containers
```yaml
# optimized-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: optimized-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        resources:
          requests:
            cpu: 200m      # Start conservative
            memory: 256Mi
          limits:
            cpu: 500m      # Allow burst capacity
            memory: 512Mi
        # Readiness probe for scaling decisions
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        # Liveness probe for reliability
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

#### Quality of Service Classes
```yaml
# Different QoS classes for different workloads

# Guaranteed QoS (critical workloads)
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 500m      # Same as requests
    memory: 1Gi    # Same as requests

# Burstable QoS (most workloads)
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m     # Higher than requests
    memory: 1Gi    # Higher than requests

# BestEffort QoS (batch jobs, dev environments)
# No resource requests or limits specified
```

### Node Upgrade Strategies

#### Rolling Updates
```bash
# Drain node for maintenance
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data

# Upgrade node (cloud provider specific)
# AWS: Update launch template and terminate instance
# Azure: Upgrade node pool
# GKE: Upgrade node pool

# Uncordon node
kubectl uncordon node-1
```

#### Blue-Green Node Pool Strategy
```bash
# Create new node pool with updated configuration
az aks nodepool add \
  --resource-group myRG \
  --cluster-name myCluster \
  --name newpool \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3

# Migrate workloads using taints and tolerations
kubectl taint nodes -l agentpool=oldpool key=value:NoSchedule

# Delete old node pool after migration
az aks nodepool delete \
  --resource-group myRG \
  --cluster-name myCluster \
  --name oldpool
```

## Multi-Region Scaling

### Cross-Region Clusters

#### Federation with Admiral
```yaml
# admiral-config.yaml
apiVersion: admiral.io/v1alpha1
kind: Dependency
metadata:
  name: sample-app-dependency
spec:
  source: sample-app
  destinations:
  - greeting-service
  - user-service
---
apiVersion: admiral.io/v1alpha1
kind: GlobalTrafficPolicy
metadata:
  name: sample-app-gtp
spec:
  selector:
    identity: sample-app
  policy:
  - dns: sample-app.global
    lbType: 1  # Round-robin
    target:
    - region: us-west-2
      weight: 50
    - region: eu-west-1
      weight: 50
```

#### Cluster Mesh with Linkerd
```bash
# Install Linkerd on each cluster
linkerd install --cluster-name=cluster-1 | kubectl apply -f -
linkerd install --cluster-name=cluster-2 | kubectl apply -f -

# Set up cluster linking
linkerd --context=cluster-1 multicluster link --cluster-name cluster-1 \
  | kubectl --context=cluster-2 apply -f -

linkerd --context=cluster-2 multicluster link --cluster-name cluster-2 \
  | kubectl --context=cluster-1 apply -f -
```

### Disaster Recovery

#### Backup and Restore with Velero
```bash
# Install Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.2.1 \
  --bucket my-backup-bucket \
  --secret-file ./credentials-velero

# Create backup schedule
velero schedule create daily-backup --schedule="0 1 * * *"

# Restore from backup
velero restore create --from-backup daily-backup-20231201010000
```

## Monitoring Scaling Events

### Scaling Metrics

#### HPA Metrics Dashboard
```json
{
  "dashboard": {
    "title": "HPA Scaling Metrics",
    "panels": [
      {
        "title": "HPA Scaling Events",
        "type": "timeseries",
        "targets": [
          {
            "expr": "kube_horizontalpodautoscaler_status_current_replicas",
            "legendFormat": "Current Replicas - {{horizontalpodautoscaler}}"
          },
          {
            "expr": "kube_horizontalpodautoscaler_status_desired_replicas",
            "legendFormat": "Desired Replicas - {{horizontalpodautoscaler}}"
          }
        ]
      },
      {
        "title": "CPU Utilization",
        "type": "timeseries",
        "targets": [
          {
            "expr": "kube_horizontalpodautoscaler_status_current_metrics_average_utilization{metric_name=\"cpu\"}",
            "legendFormat": "CPU Utilization - {{horizontalpodautoscaler}}"
          }
        ]
      }
    ]
  }
}
```

#### Cluster Resource Usage
```yaml
# monitoring-rules.yaml
groups:
- name: scaling
  rules:
  - alert: HighNodeCPUUsage
    expr: (1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance)) * 100 > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on node {{ $labels.instance }}"

  - alert: NodeMemoryPressure
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage on node {{ $labels.instance }}"

  - alert: HPAMaxReplicasReached
    expr: kube_horizontalpodautoscaler_status_current_replicas == kube_horizontalpodautoscaler_spec_max_replicas
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "HPA {{ $labels.horizontalpodautoscaler }} has reached maximum replicas"
```

## Cost Optimization

### Resource Efficiency

#### Cluster Optimization Script
```bash
#!/bin/bash
# cluster-optimization.sh

echo "🔍 Analyzing cluster resource utilization..."

# Find over-provisioned deployments
kubectl top pods --all-namespaces --containers | \
  awk 'NR>1 {if($3+0 < 50 && $4+0 < 200) print $1 "/" $2 " - CPU: " $3 " Memory: " $4}' | \
  head -20

echo "💰 Checking for unused resources..."

# Find deployments with 0 replicas
kubectl get deployments --all-namespaces -o json | \
  jq -r '.items[] | select(.status.replicas == 0) | "\(.metadata.namespace)/\(.metadata.name)"'

# Find unused services
kubectl get services --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.selector | length == 0) | "\(.metadata.namespace)/\(.metadata.name)"'

echo "📊 Resource requests vs limits analysis..."
kubectl describe nodes | grep -A 5 "Allocated resources"
```

#### Spot Instance Integration
```yaml
# spot-nodepool.yaml (AWS)
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: spot-cluster
nodeGroups:
- name: spot-workers
  instanceTypes: ["t3.medium", "t3.large", "m5.large"]
  spot: true
  minSize: 1
  maxSize: 10
  desiredCapacity: 3
  labels:
    node-type: spot
  taints:
  - key: spot-instance
    value: "true"
    effect: NoSchedule
```

```yaml
# toleration for spot instances
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-job
spec:
  template:
    spec:
      tolerations:
      - key: spot-instance
        operator: Equal
        value: "true"
        effect: NoSchedule
      nodeSelector:
        node-type: spot
```

## Best Practices

### Scaling Guidelines

1. **Start Small, Scale Gradually**
   - Begin with conservative resource requests
   - Use HPA with appropriate metrics
   - Monitor and adjust based on real usage

2. **Implement Circuit Breakers**
   ```yaml
   # Rate limiting with istio
   apiVersion: networking.istio.io/v1alpha3
   kind: DestinationRule
   metadata:
     name: circuit-breaker
   spec:
     host: sample-app
     trafficPolicy:
       connectionPool:
         tcp:
           maxConnections: 10
         http:
           http1MaxPendingRequests: 10
           maxRequestsPerConnection: 2
       outlierDetection:
         consecutiveErrors: 3
         interval: 30s
         baseEjectionTime: 30s
   ```

3. **Use Appropriate Scaling Policies**
   - Fast scale-up for traffic spikes
   - Gradual scale-down to avoid thrashing
   - Set minimum replicas for availability

4. **Monitor Scaling Decisions**
   - Track HPA behavior
   - Alert on scaling events
   - Review resource utilization regularly

### Testing Scaling

#### Load Testing with k6
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp up
    { duration: '5m', target: 100 },  // Stay at peak
    { duration: '2m', target: 0 },    // Ramp down
  ],
};

export default function() {
  let response = http.get('http://app.local/api/health');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
```

```bash
# Run load test
k6 run load-test.js

# Monitor HPA during test
watch kubectl get hpa
```

## Troubleshooting

### Common Scaling Issues

**HPA Not Scaling:**
```bash
# Check HPA status
kubectl describe hpa sample-app-hpa

# Verify metrics server
kubectl top nodes
kubectl top pods

# Check resource requests are set
kubectl describe deployment sample-app
```

**Node Scaling Issues:**
```bash
# Check cluster autoscaler logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# Verify node group configuration
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name my-nodegroup
```

**Performance Degradation:**
```bash
# Check resource limits
kubectl describe nodes

# Monitor pod evictions
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Next Steps

- [Monitor scaling with Grafana](/docs/grafana/scaling-dashboards/)
- [Implement cost monitoring](/docs/recipes/cost-optimization/)
- [Set up multi-cluster federation](/docs/recipes/multi-cluster/)
- [Configure disaster recovery](/docs/recipes/disaster-recovery/)