# Roadmap

A Helm chart that deploys [bakery-orders-api](https://github.com/b0tjim/bakery-orders-api) to a local
[kind](https://kind.sigs.k8s.io/) cluster, with Prometheus + Grafana (kube-prometheus-stack) scraping the
app's `/metrics` endpoint and a provisioned Grafana dashboard. CI spins up kind and smoke-tests it all.

- [x] 1. Repo skeleton: README stub, .gitignore, .editorconfig, LICENSE
- [x] 2. `kind/cluster.yaml` (one control-plane node, port mapping for the app) + `make cluster-up` / `cluster-down`
- [x] 3. Script to get the app image into kind: build bakery-orders-api from source and `kind load docker-image` (works without a published GHCR tag)
- [x] 4. Helm chart scaffold `charts/bakery-orders-api`: Chart.yaml, values.yaml, `_helpers.tpl` (names + labels)
- [x] 5. Chart: PostgreSQL StatefulSet + Service + Secret for local dev (small, in-chart, no external subchart)
- [x] 6. Chart: app Deployment with `DATABASE_URL` from the Secret, resource requests/limits
- [x] 7. Chart: liveness/readiness probes on `/health`, and a ClusterIP Service exposing port 8000
- [x] 8. `helm lint` and `helm template` pass; add a `values-kind.yaml` (local image, `pullPolicy: Never`)
- [x] 9. CI workflow: `helm lint` + kubeconform validation of rendered manifests on every push
- [x] 10. CI workflow: create a kind cluster, load the image, `helm install`, wait for rollout
- [ ] 11. CI smoke test: port-forward and `curl` `/health`, create an order, list it back
- [ ] 12. Install kube-prometheus-stack via `make monitoring-up` with a pinned chart version and `monitoring/values.yaml`
- [ ] 13. Chart: optional ServiceMonitor (toggled by `metrics.serviceMonitor.enabled`) scraping `/metrics`
- [ ] 14. Grafana dashboard JSON (request rate, latency, error rate, orders created) in `dashboards/`
- [ ] 15. Chart: ConfigMap with the `grafana_dashboard` label so Grafana's sidecar auto-loads the dashboard
- [ ] 16. A couple of PrometheusRule alerts (app down, high 5xx rate)
- [ ] 17. CI: install the monitoring stack in kind and assert Prometheus has the app target `up`
- [ ] 18. `scripts/load.sh` to generate traffic so the dashboard has something to show
- [ ] 19. README: architecture diagram (Mermaid), what it demonstrates, step-by-step how to run it locally
- [ ] 20. Badges, dashboard screenshot or description, final polish, tag `v0.1.0`
