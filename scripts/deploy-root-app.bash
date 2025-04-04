#!/bin/bash

# This script deploys the root application that manages all other apps
# It implements the "App of Apps" pattern in ArgoCD

set -e

# Default values
NAMESPACE="argocd"
CONTEXT=$(kubectl config current-context)

function show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -n, --namespace NAMESPACE  ArgoCD namespace (default: argocd)"
  echo "  -c, --context CONTEXT      Kubernetes context to use (default: current context)"
  echo "  -h, --help                 Show this help message"
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -c|--context)
      CONTEXT="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

echo "Deploying root application to context: $CONTEXT, namespace: $NAMESPACE"

# Switch to the specified context
kubectl config use-context "$CONTEXT"

# Apply the root ApplicationSet
kubectl apply -f argocd/applicationsets/root-appset.yaml -n "$NAMESPACE"

echo "Root ApplicationSet deployed successfully!"
echo "This will create applications for all clusters defined in clusters/clusters.yaml"
echo "Check the status with: argocd app list"
