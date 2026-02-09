.PHONY: build docker cluster deploy test clean all observe ports jaeger-ui grafana-ui

CLUSTER_NAME := chainbench
IMAGE_NAME := chainbench:latest
NAMESPACE := chainbench

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
	kubectl -n $(NAMESPACE) wait --for=condition=ready pod --all --timeout=120s

observe:
	@echo "Deploying observability stack..."
	kubectl apply -f deploy/observability/prometheus-config.yaml
	kubectl apply -f deploy/observability/prometheus.yaml
	kubectl apply -f deploy/observability/jaeger.yaml
	kubectl create configmap grafana-dashboards \
		--from-file=deploy/observability/grafana-dashboards/ \
		-n $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f deploy/observability/grafana.yaml
	@echo "Waiting for observability pods to be ready..."
	kubectl -n $(NAMESPACE) wait --for=condition=ready pod -l app=prometheus --timeout=120s
	kubectl -n $(NAMESPACE) wait --for=condition=ready pod -l app=jaeger --timeout=120s
	kubectl -n $(NAMESPACE) wait --for=condition=ready pod -l app=grafana --timeout=120s
	@echo ""
	@echo "Observability stack deployed. Run 'make ports' to access UIs."

ports:
	@chmod +x deploy/observability/port-forward.sh
	@deploy/observability/port-forward.sh

jaeger-ui:
	@open http://localhost:16686 2>/dev/null || xdg-open http://localhost:16686 2>/dev/null || echo "Open http://localhost:16686 in your browser"

grafana-ui:
	@open http://localhost:3000 2>/dev/null || xdg-open http://localhost:3000 2>/dev/null || echo "Open http://localhost:3000 in your browser (admin / chainbench)"

test:
	@echo "Smoke test: calling gateway /chain endpoint..."
	@curl -s http://localhost:30080/chain | python3 -m json.tool || echo "Gateway not reachable yet"

clean:
	kind delete cluster --name $(CLUSTER_NAME) 2>/dev/null || true
