CLUSTER_NAME ?= bakery-lab

.PHONY: cluster-up cluster-down image install lint validate

cluster-up: ## Create the local kind cluster
	kind create cluster --config kind/cluster.yaml --name $(CLUSTER_NAME) --wait 60s

cluster-down: ## Delete the local kind cluster
	kind delete cluster --name $(CLUSTER_NAME)

image: ## Build bakery-orders-api from source and load it into kind
	CLUSTER_NAME=$(CLUSTER_NAME) scripts/load-image.sh

install: ## Install (or upgrade) the chart into kind and wait for it to be ready
	helm upgrade --install bakery charts/bakery-orders-api -f charts/bakery-orders-api/values-kind.yaml --wait --timeout 5m
	kubectl rollout status deployment/bakery-bakery-orders-api --timeout 2m

lint: ## Lint the chart and render it with the kind values
	helm lint charts/bakery-orders-api -f charts/bakery-orders-api/values-kind.yaml
	helm template bakery charts/bakery-orders-api -f charts/bakery-orders-api/values-kind.yaml > /dev/null

validate: ## Validate rendered manifests against Kubernetes schemas (needs kubeconform)
	for v in values.yaml values-kind.yaml; do \
		helm template bakery charts/bakery-orders-api -f charts/bakery-orders-api/$$v \
			| kubeconform -strict -summary -kubernetes-version 1.31.0 || exit 1; \
	done
