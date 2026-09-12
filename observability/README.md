# Observability

The application exposes Prometheus metrics at `/metrics`, a health endpoint at
`/health`, and JSON logs on stdout for Loki collection.

## Deploy the platform

Install the Prometheus Operator and Grafana with `kube-prometheus-stack`:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

Install Loki and its log collector:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install loki grafana/loki \
  --namespace monitoring --create-namespace \
  --set deploymentMode=SingleBinary \
  --set loki.auth_enabled=false
helm upgrade --install alloy grafana/alloy \
  --namespace monitoring \
  --set alloy.configMap.content='''
logging { level = "info" }
discovery.kubernetes "pods" { role = "pod" }
prometheus.scrape "app" { targets = discovery.kubernetes.pods.targets }
'''
```

Configure the application chart to create a Prometheus Operator `ServiceMonitor`:

```bash
helm upgrade --install jenkins-nodejs-app ./helm/jenkins-nodejs-app \
  --namespace jenkins-demo --create-namespace \
  --set observability.serviceMonitor.enabled=true
```

Prometheus will scrape `/metrics`. Grafana is included in the monitoring stack;
use the Prometheus data source for metrics and the Loki data source pointing to
`http://loki-gateway.monitoring.svc.cluster.local` for logs.