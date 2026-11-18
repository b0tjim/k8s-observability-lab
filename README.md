# k8s-observability-lab

[![CI](https://github.com/b0tjim/k8s-observability-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/b0tjim/k8s-observability-lab/actions/workflows/ci.yml)
[![Helm](https://img.shields.io/badge/helm-3-0F1689.svg)](charts/bakery-orders-api/Chart.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Deploys [bakery-orders-api](https://github.com/b0tjim/bakery-orders-api) to a local
[kind](https://kind.sigs.k8s.io/) cluster with a Helm chart, then watches it with Prometheus + Grafana
(kube-prometheus-stack).

Built step by step; see [ROADMAP.md](ROADMAP.md) for the history.

## Architecture

```mermaid
flowchart LR
  subgraph kind["kind cluster (bakery-lab)"]
    subgraph default["namespace: default (Helm release: bakery)"]
      api["bakery-orders-api<br/>Deployment"] -->|DATABASE_URL from Secret| pg[("PostgreSQL<br/>StatefulSet")]
      svc["Service :8000"] --> api
      sm["ServiceMonitor"] -.-> svc
      rule["PrometheusRule<br/>(app down, high 5xx)"]
      cm["ConfigMap<br/>grafana_dashboard=1"]
    end
    subgraph monitoring["namespace: monitoring (kube-prometheus-stack)"]
      prom["Prometheus"] -->|scrapes /metrics| svc
      prom -. loads .-> rule
      graf["Grafana"] -->|queries| prom
      graf -. sidecar loads .-> cm
    end
  end
  dev["you / CI"] -->|kubectl port-forward| svc
  dev -->|kubectl port-forward| graf
```

## What it demonstrates

- **Helm chart authoring**: templated Deployment, Service, PostgreSQL StatefulSet and Secret, shared
  name/label helpers, probes, resource limits, and optional monitoring objects behind values flags.
- **Prometheus Operator patterns**: a `ServiceMonitor` for scraping, `PrometheusRule` alerts, and a Grafana
  dashboard shipped as code (a labelled ConfigMap the Grafana sidecar picks up).
- **Local Kubernetes with kind**: building the app image from source and side-loading it, so nothing depends
  on a registry.
- **CI that actually deploys**: every push runs `helm lint` + kubeconform, then creates a kind cluster,
  installs the chart, smoke-tests the API, installs the monitoring stack and asserts Prometheus sees the app
  target as `up`.

## Prerequisites

- Docker
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- kubectl
- Helm 3

## Quick start

```bash
make cluster-up     # single-node kind cluster named bakery-lab
kubectl get nodes
make image          # build bakery-orders-api from source, kind load it as bakery-orders-api:local
make install        # deploy the chart (app + PostgreSQL) and wait for rollout
make smoke          # /health, create an order, list it back
make monitoring-up  # kube-prometheus-stack (pinned version) into the monitoring namespace
make install HELM_ARGS="--set metrics.serviceMonitor.enabled=true --set metrics.prometheusRule.enabled=true"
make check-metrics  # assert Prometheus has the app target up
make load           # send ~300 mixed requests so the Grafana dashboard has data
make cluster-down   # tear it down
```

The ServiceMonitor and PrometheusRule are off by default because their CRDs only exist once
kube-prometheus-stack is installed, which is why the chart is upgraded a second time above.

### Look at it

```bash
# Grafana: http://localhost:3000 (admin / admin, local-only). Dashboard: "Bakery Orders API"
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

# Prometheus: http://localhost:9090 (Status -> Targets, and the Alerts page)
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090

# The API itself: http://localhost:8000/docs
kubectl port-forward svc/bakery-bakery-orders-api 8000:8000
```

### The dashboard

"Bakery Orders API" has a `job` variable (defaults to all) and four panels, all built from the
`http_requests_total` counter and `http_request_duration_seconds` histogram the app exposes on `/metrics`:

| Panel | PromQL idea |
|-------|-------------|
| Request rate | `rate(http_requests_total[5m])` by method and path |
| Latency p50 / p95 | `histogram_quantile` over the duration buckets, per path |
| Error rate (5xx share) | 5xx requests / all requests |
| Orders created | `increase` of successful `POST /orders` over the selected range |

Run `make load` first so the panels have data. No screenshot is checked in: the lab runs on a throwaway
kind cluster, so the honest way to see it is to run it.

`make lint` and `make validate` (needs kubeconform) work without a cluster.

## Layout

- `kind/cluster.yaml` - single-node kind cluster config
- `scripts/load.sh` - port-forwards the app and sends mixed traffic (creates, reads, a few 404/422s)
- `scripts/load-image.sh` - builds the app image from source and loads it into kind
- `charts/bakery-orders-api/` - Helm chart for the app, PostgreSQL, and optional ServiceMonitor/PrometheusRule
- `scripts/smoke-test.sh`, `scripts/check-prometheus-target.sh` - checks used by `make smoke` / `make check-metrics` and CI
- `.github/workflows/ci.yml` - lint/validate job plus the full kind deploy job
- `charts/bakery-orders-api/dashboards/bakery-orders-api.json` - Grafana dashboard (request rate, p50/p95 latency, 5xx error rate, orders created), shipped as a `grafana_dashboard` ConfigMap so Grafana auto-loads it
- `monitoring/values.yaml` - kube-prometheus-stack values tuned for kind (no Alertmanager, kind-unreachable control-plane targets off)

## License

MIT
