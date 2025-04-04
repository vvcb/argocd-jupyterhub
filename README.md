# JupyterHub on Kubernetes with ArgoCD

This repository contains configuration to deploy JupyterHub on Kubernetes using ArgoCD.

## Prerequisites

- Kubernetes cluster
- ArgoCD installed on the cluster
- `kubectl` configured to connect to your cluster
- Helm 3

## Setup

1. Install ArgoCD (if not already installed)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. Access the ArgoCD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

3. Login using the default credentials (username: `admin`, password can be retrieved with):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Deployment

1. Apply the ArgoCD Application resources:

```bash
kubectl apply -f argocd/applications/
```

2. Access JupyterHub:

```bash
kubectl port-forward -n jupyterhub svc/proxy-public 8000:80
```

## Directory Structure

- `base/`: Base Kustomize configuration for JupyterHub
- `overlays/`: Environment-specific Kustomize configurations
  - `dev/`
  - `staging/`
  - `prod/`
- `argocd/`: ArgoCD specific configurations
  - `applications/`: ArgoCD Application resources
- `chart-values/`: Helm chart values for different environments

## Customization

Edit the files in the environment-specific overlays to customize JupyterHub for your needs.