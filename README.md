# ChainBench: Measuring Cold-Start Tail-Latency Amplification in Kubernetes Microservice Chains

ChainBench is an instrumented microservice chain benchmark for measuring how Kubernetes pod cold-start latency amplifies tail latency across multi-hop service chains. It deploys a 7-service chain on a local kind cluster, with each service injecting configurable log-normal cold-start delays and CPU busy-wait work. Distributed traces (via OpenTelemetry/Jaeger) and Prometheus metrics enable precise measurement of per-hop and end-to-end latency distributions. This project accompanies a poster abstract submitted to USENIX NSDI '26.

## Prerequisites

- Go 1.21+
- Docker
- [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker)
- kubectl
- curl (for smoke tests)

## Quick Start

```bash
git clone https://github.com/chainbench/chainbench.git
cd chainbench
chmod +x scripts/setup.sh
./scripts/setup.sh
curl http://localhost:30080/chain | python3 -m json.tool
```

## Architecture

```
                        7-Service Chain (kind cluster)

  Client
    |
    v
+---------+    +------+    +-------------+    +-----------+
| Gateway |───>| Auth |───>| UserProfile |───>| Recommend |
| (pos 1) |    |(pos 2)|   |   (pos 3)   |    |  (pos 4)  |
+---------+    +------+    +-------------+    +-----------+
                                                    |
                                                    v
                                              +-----------+    +---------+    +------------+
                                              | Inventory |───>| Pricing |───>| Aggregator |
                                              |  (pos 5)  |    | (pos 6) |    |  (pos 7)   |
                                              +-----------+    +---------+    +------------+

  Each service:
  ┌─────────────────────────────────────┐
  │  1. Cold-start injection            │  P(inject) = COLD_START_PROBABILITY
  │     delay ~ LogNormal(median, σ)    │  Models K8s pod cold-start
  │  2. CPU busy-wait (SERVICE_WORK_MS) │  Simulates real computation
  │  3. Call next service via HTTP      │  Propagates OTel trace context
  │  4. Return JSON response            │  Includes timing + downstream
  └─────────────────────────────────────┘
```

## Configuration Reference

| Environment Variable           | Description                                  | Default |
|--------------------------------|----------------------------------------------|---------|
| `SERVICE_NAME`                 | Name of this service instance                | `service` |
| `SERVICE_PORT`                 | HTTP listen port                             | `8080`  |
| `NEXT_SERVICE_URL`             | URL of next service in chain (empty = tail)  | (empty) |
| `SERVICE_WORK_MS`              | CPU busy-wait duration per request (ms)      | `5`     |
| `COLD_START_PROBABILITY`       | Probability of cold-start injection (0.0-1.0)| `0.0`   |
| `COLD_START_MEDIAN_MS`         | Median cold-start delay (ms)                 | `2100`  |
| `COLD_START_SIGMA`             | Log-normal sigma parameter                   | `0.4`   |
| `OTEL_EXPORTER_JAEGER_ENDPOINT`| Jaeger OTLP/HTTP collector endpoint          | (empty) |
| `OTEL_SERVICE_NAME`            | Override service name for traces             | `SERVICE_NAME` |

## Endpoints

| Path       | Description                              |
|------------|------------------------------------------|
| `/chain`   | Main chain handler (calls downstream)    |
| `/healthz` | Kubernetes readiness probe (returns 200) |
| `/metrics` | Prometheus metrics endpoint              |

## Makefile Targets

| Target    | Description                          |
|-----------|--------------------------------------|
| `build`   | Build the Go binary locally          |
| `docker`  | Build Docker image and load into kind|
| `cluster` | Create kind cluster                  |
| `deploy`  | Deploy all 7 services                |
| `test`    | Run smoke test against gateway       |
| `clean`   | Tear down kind cluster               |

## Citation

```bibtex
@inproceedings{chainbench-nsdi26,
  title     = {{ChainBench}: Measuring Cold-Start Tail-Latency Amplification
               in {Kubernetes} Microservice Chains},
  author    = {Sanket},
  booktitle = {Poster at the 23rd USENIX Symposium on Networked Systems
               Design and Implementation (NSDI '26)},
  year      = {2026}
}
```
