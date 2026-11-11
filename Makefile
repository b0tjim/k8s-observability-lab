CLUSTER_NAME ?= bakery-lab

.PHONY: cluster-up cluster-down

cluster-up: ## Create the local kind cluster
	kind create cluster --config kind/cluster.yaml --name $(CLUSTER_NAME) --wait 60s

cluster-down: ## Delete the local kind cluster
	kind delete cluster --name $(CLUSTER_NAME)
