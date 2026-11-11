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
make cluster-down   # tear it down
```

## Layout

- `kind/cluster.yaml` - single-node kind cluster config
- `scripts/load-image.sh` - builds the app image from source and loads it into kind
- `charts/bakery-orders-api/` - Helm chart for the app (in progress)

## License

MIT
