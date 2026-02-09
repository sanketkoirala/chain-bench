#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="chainbench"

echo "=== ChainBench Port Forwards ==="
echo "Starting port forwards (Ctrl+C to stop all)..."
echo ""

# Cleanup background processes on exit
trap 'echo "Stopping port forwards..."; kill $(jobs -p) 2>/dev/null; exit 0' INT TERM

# Jaeger UI: localhost:16686
kubectl port-forward -n "${NAMESPACE}" svc/jaeger-query 16686:16686 &
echo "  Jaeger UI:   http://localhost:16686"

# Prometheus: localhost:9090
kubectl port-forward -n "${NAMESPACE}" svc/prometheus 9090:9090 &
echo "  Prometheus:  http://localhost:9090"

# Grafana: localhost:3000
kubectl port-forward -n "${NAMESPACE}" svc/grafana 3000:3000 &
echo "  Grafana:     http://localhost:3000  (admin / chainbench)"

# Kiali: localhost:20001
kubectl port-forward -n istio-system svc/kiali 20001:20001 2>/dev/null &
echo "  Kiali:       http://localhost:20001  (if Istio addons installed)"

echo ""
echo "All port forwards active. Press Ctrl+C to stop."
wait
