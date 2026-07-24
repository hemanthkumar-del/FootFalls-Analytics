# Kubernetes Guide

This guide covers deploying FootFalls Analytics to a Kubernetes cluster.

## Prerequisites
- `kubectl` installed and configured.
- An active Kubernetes Cluster (e.g., Minikube, EKS, AKS).
- NGINX Ingress Controller installed.

## Deployment Steps

1. **Create Namespace**
   ```bash
   kubectl apply -f k8s/namespace.yaml
   ```

2. **Apply Configuration & Secrets**
   *Note: Edit `secret.yaml` with your actual base64 encoded strings or configure Azure Key Vault before running this.*
   ```bash
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/secret.yaml
   ```

3. **Deploy Backend & Service**
   ```bash
   kubectl apply -f k8s/backend-deployment.yaml
   kubectl apply -f k8s/backend-service.yaml
   ```

4. **Apply Autoscaling & Network Policies**
   ```bash
   kubectl apply -f k8s/hpa.yaml
   kubectl apply -f k8s/network-policy.yaml
   ```

5. **Expose Ingress**
   ```bash
   kubectl apply -f k8s/ingress.yaml
   ```

## Managing Workers
Since OpenCV workloads are hardware-intensive, the Horizontal Pod Autoscaler (HPA) will automatically spin up additional replicas when CPU usage exceeds 75%. Note that RTSP camera streams are handled dynamically by the `CameraWorkerRegistry`. When scaling horizontally, ensure your MongoDB replica sets are configured to handle concurrent heartbeats.
