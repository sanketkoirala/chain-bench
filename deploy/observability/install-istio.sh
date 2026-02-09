#!/usr/bin/env bash
set -euo pipefail

ISTIO_VERSION="1.20.0"
ISTIO_DIR="istio-${ISTIO_VERSION}"
NAMESPACE="chainbench"

echo "=== ChainBench Istio Installer ==="

# Download istioctl if not present
if ! command -v istioctl &>/dev/null; then
  if [ ! -d "${ISTIO_DIR}" ]; then
    echo "[1/5] Downloading Istio ${ISTIO_VERSION}..."
    curl -sL "https://istio.io/downloadIstio" | ISTIO_VERSION="${ISTIO_VERSION}" sh -
  fi
  export PATH="${PWD}/${ISTIO_DIR}/bin:${PATH}"
  echo "Using istioctl from ${PWD}/${ISTIO_DIR}/bin"
else
  echo "[1/5] istioctl already installed: $(istioctl version --short 2>/dev/null || echo 'unknown')"
fi

# Install Istio with demo profile
echo "[2/5] Installing Istio with demo profile..."
istioctl install --set profile=demo -y

# Enable sidecar injection on chainbench namespace
echo "[3/5] Enabling sidecar injection on namespace '${NAMESPACE}'..."
kubectl create namespace "${NAMESPACE}" 2>/dev/null || true
kubectl label namespace "${NAMESPACE}" istio-injection=enabled --overwrite

# Wait for Istio pods
echo "[4/5] Waiting for Istio system pods to be ready..."
kubectl -n istio-system wait --for=condition=ready pod --all --timeout=180s

# Install addons (Kiali, Jaeger, Prometheus, Grafana)
echo "[5/5] Installing Istio addons (Kiali, Jaeger, Prometheus, Grafana)..."
ADDONS_DIR="${ISTIO_DIR}/samples/addons"
if [ -d "${ADDONS_DIR}" ]; then
  kubectl apply -f "${ADDONS_DIR}/kiali.yaml" 2>/dev/null || true
  kubectl apply -f "${ADDONS_DIR}/jaeger.yaml" 2>/dev/null || true
  kubectl apply -f "${ADDONS_DIR}/prometheus.yaml" 2>/dev/null || true
  kubectl apply -f "${ADDONS_DIR}/grafana.yaml" 2>/dev/null || true
  # Retry once — CRDs sometimes need a moment
  sleep 5
  kubectl apply -f "${ADDONS_DIR}" 2>/dev/null || true
  echo "Waiting for addon pods..."
  kubectl -n istio-system wait --for=condition=ready pod --all --timeout=120s
else
  echo "WARNING: Addons directory not found at ${ADDONS_DIR}"
  echo "You may need to install addons manually."
fi

echo ""
echo "=== Istio installation complete ==="
echo "Namespace '${NAMESPACE}' has sidecar injection enabled."
echo "Run 'kubectl get pods -n istio-system' to verify."
