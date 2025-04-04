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

## Deployment

### Option 1: Using kubectl

1. Apply the ArgoCD Application resources:

```bash
kubectl apply -f argocd/applications/
```

### Option 2: Using ArgoCD UI

1. Access the ArgoCD UI as described in the Setup section

2. Click on "+ NEW APP" to create a new application.

3. For the dev environment, fill in the form as follows:
   - Application Name: `jupyterhub-dev`
   - Project: `default`
   - Sync Policy: Choose `Automatic` with "Prune Resources" and "Self Heal" enabled
   - Repository URL: `https://github.com/vvcb/argocd-jupyterhub`
   - Revision: `HEAD`
   - Path: `overlays/dev`
   - Destination: `https://kubernetes.default.svc`
   - Namespace: `jupyterhub-dev`
   - Check "Directory Recurse" if needed
   - Click "CREATE" to create the application

4. Similarly create applications for staging and production environments:
   - Use the same repository but different paths (`overlays/staging` and `overlays/prod`)
   - Use different namespaces (`jupyterhub-staging` and `jupyterhub-prod`)
   - For production, you might want to set Sync Policy to "Manual" for more control

5. After creating the applications, you can view them in the ArgoCD dashboard and trigger a sync if not set to automatic.

## Accessing Applications

### JupyterHub

```bash
kubectl port-forward -n jupyterhub-dev svc/dev-proxy-public 8000:80
```

### Example App

```bash
kubectl port-forward -n example-app-dev svc/dev-example-app 8080:80
```

## Directory Structure

```
├── apps/                       # All applications
│   ├── jupyterhub/             # JupyterHub specific configurations
│   │   ├── base/               # Base Kustomize configuration
│   │   └── overlays/           # Environment-specific configurations
│   │       ├── dev/
│   │       ├── staging/
│   │       └── prod/
│   └── example-app/            # Example application
│       ├── base/
│       └── overlays/
│           ├── dev/
│           ├── staging/
│           └── prod/
├── argocd/                     # ArgoCD specific configurations
│   ├── applications/           # Application definitions
│   └── argocd-cm.yaml          # ArgoCD ConfigMap for Kustomize
└── chart-values/               # Values for Helm charts
    ├── jupyterhub/             # JupyterHub values
    │   ├── values.yaml         # Default values
    │   └── environments/       # Environment-specific values
    │       ├── dev-values.yaml
    │       ├── staging-values.yaml
    │       └── prod-values.yaml
    └── other-apps/             # Values for other applications
```

## Adding a New Application

To add a new application:

1. Create a directory structure in `apps/your-app-name/` with both `base/` and `overlays/` subdirectories
2. Create an ArgoCD Application in `argocd/applications/your-app-name.yaml`
3. If using Helm charts, add appropriate values files in `chart-values/your-app-name/`

## Customization

Edit the files in the environment-specific overlays to customize applications for your needs.

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