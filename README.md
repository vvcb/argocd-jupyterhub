# Multi-Application Deployment on Kubernetes with ArgoCD

This repository contains configuration to deploy multiple applications (including JupyterHub) on Kubernetes using ArgoCD.

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

2. Apply the ArgoCD ConfigMap to enable Helm support in Kustomize:

```bash
kubectl apply -f argocd/argocd-cm.yaml
```

3. Access the ArgoCD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

4. Login using the default credentials (username: `admin`, password can be retrieved with):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Multi-Cluster Deployment with ApplicationSet

### Step 1: Register Clusters

Register all target clusters with ArgoCD:

```bash
./scripts/register-clusters.bash
```

Make sure to edit the script first to include your actual cluster details.

### Step 2: Deploy ApplicationSets

Apply the ApplicationSet resources to deploy applications across all clusters:

```bash
kubectl apply -f argocd/applicationsets/
```

This will create Applications for each defined cluster (dev, staging, and production).

### Step 3: View Applications

In the ArgoCD UI, you'll see applications for each environment across all clusters.

## Accessing Applications

### JupyterHub

```bash
kubectl port-forward -n jupyterhub-dev svc/dev-proxy-public 8000:80
```

For staging:
```bash
kubectl port-forward -n jupyterhub-staging svc/stg-proxy-public 8000:80
```

For production:
```bash
kubectl port-forward -n jupyterhub-prod svc/prd-proxy-public 8000:80
```

### Example App

```bash
kubectl port-forward -n example-app-dev svc/dev-example-app 8080:80
```

For staging:
```bash
kubectl port-forward -n example-app-staging svc/stg-example-app 8080:80
```

For production:
```bash
kubectl port-forward -n example-app-prod svc/prd-example-app 8080:80
```

## Directory Structure

```
/
├── apps/
│   ├── jupyterhub/
│   │   ├── base/
│   │   │   ├── kustomization.yaml
│   │   │   └── jupyterhub-ns.yaml
│   │   └── overlays/
│   │       ├── dev/
│   │       │   ├── kustomization.yaml
│   │       │   └── namespace.yaml
│   │       ├── staging/
│   │       │   ├── kustomization.yaml
│   │       │   └── namespace.yaml
│   │       └── prod/
│   │           ├── kustomization.yaml
│   │           └── namespace.yaml
│   └── example-app/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml
│       │   ├── deployment.yaml
│       │   └── service.yaml
│       └── overlays/
│           ├── dev/
│           │   ├── kustomization.yaml
│           │   ├── namespace.yaml
│           │   └── deployment-patch.yaml
│           ├── staging/
│           │   ├── kustomization.yaml
│           │   ├── namespace.yaml
│           │   └── deployment-patch.yaml
│           └── prod/
│               ├── kustomization.yaml
│               ├── namespace.yaml
│               └── deployment-patch.yaml
├── argocd/
│   ├── applicationsets/
│   │   ├── jupyterhub-appset.yaml
│   │   └── example-app-appset.yaml
│   └── argocd-cm.yaml
├── chart-values/
│   ├── jupyterhub/
│   │   ├── values.yaml
│   │   └── environments/
│   │       └── dev-values.yaml
│   ├── staging-values.yaml
│   └── prod-values.yaml
├── scripts/
│   ├── get-argocd-admin-secret.bash
│   └── register-clusters.bash
└── README.md
```

## Adding a New Application

To add a new application:

1. Create a directory structure in `apps/your-app-name/` with both `base/` and `overlays/` subdirectories
2. Create an ArgoCD ApplicationSet in `argocd/applicationsets/your-app-name-appset.yaml`
3. If using Helm charts, add appropriate values files in `chart-values/your-app-name/`

## Troubleshooting

If you encounter synchronization issues in ArgoCD:

1. Check the application logs in the ArgoCD UI
2. Verify that the repository is accessible from your cluster
3. Ensure that the paths in the ArgoCD application definition match the directory structure
4. For Helm-based applications, verify that the Helm chart version is available

### Common Errors

**Error: "Resource not found in cluster: kustomize.config.k8s.io/v1beta1/HelmChartMetadata:jupyterhub"**

This error occurs when using Kustomize with Helm charts but the Helm chart integration isn't properly configured. To fix this:

1. Make sure you have applied the ArgoCD ConfigMap that enables Helm support:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  kustomize.buildOptions: "--enable-helm"
```

2. Ensure you're using a version of Kustomize that supports Helm charts (v4.1.0+)
3. Verify your kustomization.yaml follows the correct structure with helmCharts section
4. Restart ArgoCD after applying the ConfigMap changes:
```bash
kubectl rollout restart deployment argocd-repo-server -n argocd
```

For more details on using Helm charts with Kustomize, refer to the [Kustomize documentation](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/helmcharts/).