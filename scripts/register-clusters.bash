#!/bin/bash

# This script registers multiple clusters with ArgoCD

# Function to register a cluster with ArgoCD
function register_cluster() {
  local cluster_name=$1
  local server_url=$2
  local bearer_token=$3
  local ca_data=$4
  local insecure=${5:-false}
  
  echo "Registering cluster: $cluster_name"
  
  if [[ "$server_url" == "https://kubernetes.default.svc" ]]; then
    # For in-cluster config (local/dev)
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${cluster_name}-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${cluster_name}
  server: ${server_url}
  config: |
    {
      "tlsClientConfig": {
        "insecure": ${insecure}
      }
    }
EOF
  else
    # For external clusters
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${cluster_name}-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${cluster_name}
  server: ${server_url}
  config: |
    {
      "bearerToken": "${bearer_token}",
      "tlsClientConfig": {
        "insecure": ${insecure},
        "caData": "${ca_data}"
      }
    }
EOF
  fi
}

# Register clusters from the clusters.yaml file
function register_from_config() {
  CONFIG_FILE=${1:-"clusters/clusters.yaml"}
  
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file $CONFIG_FILE not found"
    exit 1
  fi
  
  echo "Registering clusters from $CONFIG_FILE"
  
  # For each cluster in the config file
  # Note: This is a simple parsing, you may want to use a proper YAML parser
  cluster_lines=$(grep -n "^- name:" "$CONFIG_FILE" | cut -d: -f1)
  
  for line in $cluster_lines; do
    # Extract cluster info
    name=$(sed -n "${line}p" "$CONFIG_FILE" | cut -d: -f2- | tr -d ' ')
    env_line=$((line + 1))
    environment=$(sed -n "${env_line}p" "$CONFIG_FILE" | cut -d: -f2- | tr -d ' ')
    url_line=$((line + 2))
    server_url=$(sed -n "${url_line}p" "$CONFIG_FILE" | cut -d: -f2- | tr -d ' ')
    
    # Default values
    bearer_token="<replace-with-${name}-cluster-token>"
    ca_data="<replace-with-base64-encoded-ca-cert>"
    insecure="false"
    
    if [[ "$server_url" == "https://kubernetes.default.svc" ]]; then
      # For in-cluster registration
      register_cluster "$name" "$server_url" "" "" "$insecure"
    else
      # For external clusters
      echo "For cluster $name, you need to provide credentials."
      echo "You can update these values later by editing the secret ${name}-cluster in the argocd namespace."
      register_cluster "$name" "$server_url" "$bearer_token" "$ca_data" "$insecure"
    fi
  done
}

# Default behavior
if [[ "$1" == "--from-config" ]]; then
  register_from_config "$2"
else
  # Legacy manual registration for backward compatibility
  # Register the development cluster (using in-cluster config)
  register_cluster "dev" "https://kubernetes.default.svc" "" "" "false"
  
  # Register the staging cluster
  register_cluster "stg" "https://stg-cluster-url.example.com" "<replace-with-stg-cluster-token>" "<replace-with-base64-encoded-ca-cert>" "false"
  
  # Register the production cluster
  register_cluster "prd" "https://prd-cluster-url.example.com" "<replace-with-prd-cluster-token>" "<replace-with-base64-encoded-ca-cert>" "false"
fi

echo "Clusters registered with ArgoCD"
echo "After providing actual credentials for external clusters, run ./scripts/deploy-root-app.bash to deploy the app of apps pattern"
