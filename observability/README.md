# Observability

The application exposes Prometheus metrics at `/metrics`, a health endpoint at
`/health`, and JSON logs on stdout for Loki collection.

This project exposes application metrics and structured logs for Prometheus,
Grafana, Loki, and Promtail.

## Application Signals

The Node.js service provides:

- `/health` - JSON health response used by Kubernetes probes.
- `/metrics` - Prometheus metrics.
- `/` - application response.
- JSON logs on stdout - collected by Promtail and sent to Loki.

Metrics include HTTP request totals, request duration histograms, response
status labels, and default Node.js process metrics.

## Install The Monitoring Stack

Add the Helm repositories:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install Prometheus and Grafana:

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.service.type=ClusterIP \
  --set prometheus.service.type=ClusterIP
```

Install Loki as a small single-binary deployment and Promtail as a single
replica. The reduced configuration is suitable for the current three-node
cluster. For production, use object storage and scale the components.

```bash
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --create-namespace \
  --set deploymentMode=SingleBinary \
  --set loki.auth_enabled=false \
  --set loki.storage.type=filesystem \
  --set loki.useTestSchema=true \
  --set singleBinary.replicas=1 \
  --set singleBinary.persistence.storageClass=gp2 \
  --set write.replicas=0 \
  --set read.replicas=0 \
  --set backend.replicas=0 \
  --set lokiCanary.enabled=false \
  --set test.enabled=false \
  --set chunksCache.enabled=false \
  --set resultsCache.enabled=false \
  --set gateway.enabled=true

helm upgrade --install promtail grafana/promtail \
  --namespace monitoring \
  --create-namespace \
  --set daemonset.enabled=false \
  --set deployment.enabled=true \
  --set deployment.replicaCount=1 \
  --set 'config.clients[0].url=http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push'
```

## Deploy The Application

The Helm chart exposes a metrics service port and an opt-in Prometheus
Operator `ServiceMonitor`. Enable it with the `monitoring` release label so
the `kube-prometheus-stack` Prometheus instance discovers it:

```bash
helm template jenkins-nodejs-app ./helm/jenkins-nodejs-app \
  --namespace nodejs-app \
  --set observability.serviceMonitor.enabled=true \
  --set observability.serviceMonitor.additionalLabels.release=monitoring \
  | kubectl apply -n nodejs-app -f -
```

For this repository, Argo CD is the deployment owner. Commit and push changes
to `helm/jenkins-nodejs-app/values.yaml`; Argo CD will reconcile the chart.
Avoid running `helm upgrade` against resources already managed by Argo CD.

## Open Grafana

Forward Grafana to the local machine:

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

Open `http://localhost:3000` and log in with username `admin`. Retrieve the
generated password with:

```bash
kubectl get secret monitoring-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

Add these Grafana data sources:

- Prometheus: `http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
- Loki: `http://loki-gateway.monitoring.svc.cluster.local`

Useful Prometheus queries:

```promql
rate(http_requests_total[5m])

histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

sum by (status_code) (rate(http_requests_total[5m]))
```

## Open Prometheus

Forward Prometheus to the local machine:

```bash
kubectl port-forward -n monitoring \
  svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Open `http://localhost:9090` and use the queries above to inspect request
rate, latency, and status codes.

## Check Status

```bash
kubectl get pods -n monitoring
kubectl get pods -n nodejs-app
kubectl get servicemonitor -n nodejs-app
kubectl get prometheus -n monitoring
```

The application pods must be `Running`, and the ServiceMonitor must exist in
the same namespace as the application Service.

## Resource Requirements

Prometheus, Grafana, Loki, and log collection add several pods. A small EKS
cluster may report `Too many pods` or `Insufficient memory`. Add node capacity
or reduce nonessential monitoring components before troubleshooting the
application.

Loki filesystem storage requires a StorageClass. This cluster uses `gp2`:

```bash
kubectl get storageclass
kubectl get pvc -n monitoring
```

For production, use durable object storage for Loki and persistent storage for
Prometheus instead of the reduced demo settings above.

