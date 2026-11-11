CLUSTER_NAME ?= bakery-lab

.PHONY: cluster-up cluster-down image

cluster-up: ## Create the local kind cluster
	kind create cluster --config kind/cluster.yaml --name $(CLUSTER_NAME) --wait 60s

cluster-down: ## Delete the local kind cluster
	kind delete cluster --name $(CLUSTER_NAME)

image: ## Build bakery-orders-api from source and load it into kind
	CLUSTER_NAME=$(CLUSTER_NAME) scripts/load-image.sh
