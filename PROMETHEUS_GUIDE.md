# Prometheus Monitoring Guide

The FootFalls FastAPI backend is instrumented with `prometheus-fastapi-instrumentator`.

## 1. Exposing Metrics
The application exposes standard metrics at `GET /metrics`.
This endpoint provides:
- HTTP Request Count (by method, path, and status)
- HTTP Request Latency
- Process CPU & Memory (via Prometheus client)

## 2. Scraping with Kubernetes
If using `kube-prometheus-stack`, apply the ServiceMonitor manifest:
```bash
kubectl apply -f k8s/service-monitor.yaml
```
Prometheus will automatically detect the `footfalls-backend-monitor` and begin scraping every 15 seconds.
