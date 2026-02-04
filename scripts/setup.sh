#!/usr/bin/env bash
set -euo pipefail

echo "=== ChainBench Setup ==="

# Check prerequisites
for cmd in go docker kind kubectl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is not installed. Please install it first."
    exit 1
  fi
done

echo "[1/5] Creating kind cluster..."
make cluster

echo "[2/5] Building Docker image..."
make docker

echo "[3/5] Deploying services..."
make deploy

echo "[4/5] Waiting for all pods to be ready..."
kubectl -n chainbench wait --for=condition=ready pod --all --timeout=120s

echo "[5/5] Running smoke test..."
sleep 5
make test

echo ""
echo "=== ChainBench is running! ==="
echo "Gateway endpoint: http://localhost:30080/chain"
echo "Metrics endpoint: http://localhost:30080/metrics"
echo ""
echo "To tear down: make clean"
