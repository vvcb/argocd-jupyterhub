#!/bin/bash

# This script registers multiple clusters with ArgoCD

# Register the development cluster (using in-cluster config)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dev-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: dev
  server: https://kubernetes.default.svc
  config: |
    {
      "tlsClientConfig": {
        "insecure": false
      }
    }
EOF

# Register the staging cluster
# Replace with your actual cluster details
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: stg-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: stg
  server: https://stg-cluster-url.example.com
  config: |
    {
      "bearerToken": "<replace-with-stg-cluster-token>",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "<replace-with-base64-encoded-ca-cert>"
      }
    }
EOF

# Register the production cluster
# Replace with your actual cluster details
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: prd-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: prd
  server: https://prd-cluster-url.example.com
  config: |
    {
      "bearerToken": "<replace-with-prd-cluster-token>",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "<replace-with-base64-encoded-ca-cert>"
      }
    }
EOF

echo "Clusters registered with ArgoCD"
