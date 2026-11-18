# k8s-observability-lab

Deploys [bakery-orders-api](https://github.com/b0tjim/bakery-orders-api) to a local
[kind](https://kind.sigs.k8s.io/) cluster with a Helm chart, then watches it with Prometheus + Grafana
(kube-prometheus-stack).

> Work in progress. See [ROADMAP.md](ROADMAP.md) for what's done and what's next.

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
make monitoring-up  # kube-prometheus-stack (pinned version) into the monitoring namespace
make load           # send ~300 mixed requests so the Grafana dashboard has data
make cluster-down   # tear it down
```

## Layout

- `kind/cluster.yaml` - single-node kind cluster config
- `scripts/load.sh` - port-forwards the app and sends mixed traffic (creates, reads, a few 404/422s)
- `scripts/load-image.sh` - builds the app image from source and loads it into kind
- `charts/bakery-orders-api/` - Helm chart for the app (in progress)
- `charts/bakery-orders-api/dashboards/bakery-orders-api.json` - Grafana dashboard (request rate, p50/p95 latency, 5xx error rate, orders created), shipped as a `grafana_dashboard` ConfigMap so Grafana auto-loads it
- `monitoring/values.yaml` - kube-prometheus-stack values tuned for kind (no Alertmanager, kind-unreachable control-plane targets off)

## License

MIT
