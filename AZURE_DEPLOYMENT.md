# Azure Deployment Guide

This document outlines the workflow for deploying FootFalls Analytics to Azure Kubernetes Service (AKS).

## 1. Push to Azure Container Registry (ACR)
1. Create an ACR instance in the Azure Portal.
2. Authenticate: `az acr login --name <your-registry-name>`
3. Build the image:
   ```bash
   docker build -t <your-registry-name>.azurecr.io/footfalls-backend:latest ./backend
   ```
4. Push the image:
   ```bash
   docker push <your-registry-name>.azurecr.io/footfalls-backend:latest
   ```

## 2. Deploy to AKS
1. Create an AKS cluster and attach it to your ACR:
   ```bash
   az aks create -n footfallsCluster -g myResourceGroup --attach-acr <your-registry-name>
   ```
2. Get credentials:
   ```bash
   az aks get-credentials --resource-group myResourceGroup --name footfallsCluster
   ```
3. Deploy the manifests:
   ```bash
   kubectl apply -f k8s/
   ```

## 3. Azure Key Vault
For enterprise security, it is highly recommended to integrate AKS with Azure Key Vault using the **Secrets Store CSI Driver** rather than applying raw `secret.yaml` files.
