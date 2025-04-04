#!/bin/bash

function switch_cluster() {
  local cluster=$1
  echo "Switching to cluster: $cluster"
  kubectl config use-context $cluster
}

# Default to kind01 cluster if no argument is provided
CLUSTER=${1:-kind01}
switch_cluster $CLUSTER

# Get the ArgoCD admin password
echo "ArgoCD admin password:"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode
echo

# Port-forward the argocd server
echo "Starting port-forward for ArgoCD server..."
kubectl port-forward svc/argocd-server 8080:80 -n argocd --address 0.0.0.0