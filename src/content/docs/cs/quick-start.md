---
title: Průvodce rychlým startem
description: Zprovozněte Flexydox za minuty
---

# Průvodce rychlým startem

Vítejte ve Flexydox! Tento průvodce vám pomůže nastavit kompletní Kubernetes vývojové prostředí s monitoringem a CI/CD za pouhých několik minut.

## Předpoklady

Před začátkem se ujistěte, že máte nainstalované následující nástroje:

- **Docker** - Container runtime
- **kind** - Kubernetes in Docker (pro lokální clustery)
- **kubectl** - Kubernetes nástroj příkazové řádky
- **helm** - Kubernetes package manager
- **make** - Nástroj pro automatizaci buildů

### Odkazy na instalaci

- [Instalace Dockeru](https://docs.docker.com/get-docker/)
- [Instalace kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Instalace kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Instalace Helm](https://helm.sh/docs/intro/install/)

## Demo jedním příkazem

Nejrychlejší způsob, jak vidět Flexydox v akci:

```bash
git clone https://github.com/flexydox/flexydox.github.io.git
cd flexydox.github.io
make demo
```

Tento jediný příkaz provede:

1. ✅ Vytvoří lokální Kubernetes cluster s kind
2. ✅ Nainstaluje NGINX Ingress Controller
3. ✅ Nasadí kompletní Grafana Stack (Prometheus, Grafana, Loki)
4. ✅ Nastaví ukázkovou aplikaci s monitoringem
5. ✅ Nakonfiguruje port forwarding pro snadný přístup
6. ✅ Poskytne přístupové URL a další kroky

## Co získáte

Po spuštění `make demo` budete mít:

### 📊 Monitoring Stack

- **Grafana** (http://localhost:3000) - admin/admin123
  - Předkonfigurované dashboardy pro Kubernetes metriky
  - Application Performance Monitoring (APM)
  - Logy aplikací s Loki
  - Alerting pravidla

- **Prometheus** - Metriky a monitoring
- **Loki** - Centralizovaný logging
- **Promtail** - Log agent

### 🚀 Ukázková aplikace

- **Nginx deployment** s 3 replikami
- Kompletní monitoring a logování
- Health check endpointy
- Vlastní metriky pro demonstraci

### 🔧 Vývojářské nástroje

```bash
# Zkontrolovat stav clusteru
make status

# Zobrazit logy aplikace
make logs

# Vyčistit demo prostředí
make clean

# Získat přístupové URL
make urls
```

## Další kroky

### 1. Prozkoumat Grafana

Otevřete http://localhost:3000 a přihlaste se pomocí:
- **Uživatel**: admin
- **Heslo**: admin123

Prozkoumat předkonfigurované dashboardy:
- Kubernetes Cluster Overview
- Node Exporter Dashboard
- Application Metrics

### 2. Nasadit vlastní aplikaci

```bash
# Použít připravené Helm charts
helm install my-app ./helm/my-application

# Nebo použít kubectl
kubectl apply -f k8s/my-app/
```

### 3. Konfigurovat monitoring

```yaml
# Přidat monitoring annotations
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
```

### 4. Přizpůsobit Grafana Stack

Upravte hodnoty v `helm/grafana-stack/values.yaml`:

```yaml
grafana:
  adminPassword: "váš-bezpečné-heslo"
  ingress:
    enabled: true
    hosts:
      - grafana.vase-domena.com

prometheus:
  retention: "30d"
  storageClass: "fast-ssd"
```

## Řešení problémů

### Cluster se nespustí

```bash
# Zkontrolovat Docker
docker version

# Resetovat kind cluster
kind delete cluster --name flexydox-demo
make demo
```

### Port forwarding nefunguje

```bash
# Zkontrolovat běžící pody
kubectl get pods -A

# Restartovat port forwarding
make port-forward
```

### Grafana není dostupná

```bash
# Zkontrolovat stav Grafana pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Získat logy
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

## Produkční nasazení

Pro produkční použití:

1. **Použijte managed Kubernetes** (AKS, EKS, GKE)
2. **Konfigurujte persistent storage**
3. **Nastavte HTTPS/TLS**
4. **Implementujte backup strategii**
5. **Konfigurujte monitoring alertů**

Podrobné instrukcepro produkční nasazení najdete v [Kubernetes Setup Guide](/cs/docs/kubernetes/setup/).

## Podpora

Potřebujete pomoc? Kontaktujte nás:

- 📖 [Dokumentace](/cs/docs/)
- 🐛 [GitHub Issues](https://github.com/flexydox/flexydox.github.io/issues)
- 💬 [Diskuze](https://github.com/flexydox/flexydox.github.io/discussions)

Gratulujeme! Máte funkční Kubernetes prostředí s kompletním monitoringem. 🎉