CLUSTER_NAME ?= bakery-lab
KPS_VERSION ?= 93.3.0
# Extra flags for `make install`, e.g. HELM_ARGS="--set metrics.serviceMonitor.enabled=true"
HELM_ARGS ?=
REQUESTS ?= 300

.PHONY: cluster-up cluster-down image install smoke load check-metrics lint validate monitoring-up monitoring-down

cluster-up: ## Create the local kind cluster
	kind create cluster --config kind/cluster.yaml --name $(CLUSTER_NAME) --wait 60s

cluster-down: ## Delete the local kind cluster
	kind delete cluster --name $(CLUSTER_NAME)

image: ## Build bakery-orders-api from source and load it into kind
	CLUSTER_NAME=$(CLUSTER_NAME) scripts/load-image.sh

install: ## Install (or upgrade) the chart into kind and wait for it to be ready
	helm upgrade --install bakery charts/bakery-orders-api -f charts/bakery-orders-api/values-kind.yaml $(HELM_ARGS) --wait --timeout 5m
	kubectl rollout status deployment/bakery-bakery-orders-api --timeout 2m

smoke: ## Port-forward the app and check /health, create an order, list it back
	scripts/smoke-test.sh

load: ## Send traffic to the app so the dashboard has data (REQUESTS=300)
	scripts/load.sh $(REQUESTS)

check-metrics: ## Assert Prometheus is scraping the app (target up)
	scripts/check-prometheus-target.sh

lint: ## Lint the chart and render it with the kind values
	helm lint charts/bakery-orders-api -f charts/bakery-orders-api/values-kind.yaml
	helm template bakery charts/bakery-orders-api -f charts/bakery-orders-api/values-kind.yaml > /dev/null

validate: ## Validate rendered manifests against Kubernetes schemas (needs kubeconform)
	for v in values.yaml values-kind.yaml; do \
		helm template bakery charts/bakery-orders-api -f charts/bakery-orders-api/$$v \
			| kubeconform -strict -summary -ignore-missing-schemas -kubernetes-version 1.31.0 || exit 1; \
	done
	# ServiceMonitor/PrometheusRule are CRDs with no built-in schema, so they are skipped; this still checks the templates render.
	helm template bakery charts/bakery-orders-api --set metrics.serviceMonitor.enabled=true --set metrics.prometheusRule.enabled=true \
		| kubeconform -strict -summary -ignore-missing-schemas -kubernetes-version 1.31.0

monitoring-up: ## Install kube-prometheus-stack (Prometheus + Grafana) into the monitoring namespace
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
		--version $(KPS_VERSION) --namespace monitoring --create-namespace \
		-f monitoring/values.yaml --wait --timeout 10m

monitoring-down: ## Remove the monitoring stack
	helm uninstall monitoring --namespace monitoring
