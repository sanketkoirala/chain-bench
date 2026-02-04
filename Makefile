.PHONY: build docker cluster deploy test clean all

CLUSTER_NAME := chainbench
IMAGE_NAME := chainbench:latest

all: cluster docker deploy

build:
	CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/service ./cmd/service

docker:
	docker build -t $(IMAGE_NAME) .
	kind load docker-image $(IMAGE_NAME) --name $(CLUSTER_NAME)

cluster:
	kind create cluster --name $(CLUSTER_NAME) --config deploy/kind-config.yaml
	kubectl apply -f deploy/namespace.yaml

deploy:
	kubectl apply -f deploy/services/gateway.yaml
	kubectl apply -f deploy/services/auth.yaml
	kubectl apply -f deploy/services/userprofile.yaml
	kubectl apply -f deploy/services/recommend.yaml
	kubectl apply -f deploy/services/inventory.yaml
	kubectl apply -f deploy/services/pricing.yaml
	kubectl apply -f deploy/services/aggregator.yaml
	@echo "Waiting for pods to be ready..."
	kubectl -n chainbench wait --for=condition=ready pod --all --timeout=120s

test:
	@echo "Smoke test: calling gateway /chain endpoint..."
	@curl -s http://localhost:30080/chain | python3 -m json.tool || echo "Gateway not reachable yet"

clean:
	kind delete cluster --name $(CLUSTER_NAME) 2>/dev/null || true
