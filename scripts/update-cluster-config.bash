#!/bin/bash

# This script helps with managing cluster configurations in the git repository

# Default config file
CONFIG_FILE="clusters/clusters.yaml"

function show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -a, --add NAME URL ENV      Add a new cluster (name, url, environment)"
  echo "  -r, --remove NAME           Remove a cluster by name"
  echo "  -l, --list                  List all configured clusters"
  echo "  -s, --sync                  Sync the root application after changes"
  echo "  -h, --help                  Show this help message"
  exit 0
}

function list_clusters() {
  echo "Configured clusters in $CONFIG_FILE:"
  echo "----------------------"
  grep "^- name:" "$CONFIG_FILE" | cut -d: -f2- | tr -d ' '
  echo "----------------------"
}

function add_cluster() {
  local name=$1
  local url=$2
  local env=$3
  
  if [[ -z "$name" || -z "$url" || -z "$env" ]]; then
    echo "Error: Missing required parameters for adding a cluster"
    echo "Usage: $0 --add NAME URL ENVIRONMENT"
    exit 1
  fi
  
  # Check if cluster already exists
  if grep -q "^- name: $name$" "$CONFIG_FILE"; then
    echo "Error: Cluster '$name' already exists in $CONFIG_FILE"
    exit 1
  fi
  
  # Add cluster to the end of the file
  cat >> "$CONFIG_FILE" << EOF
- name: $name
  environment: $env
  url: $url
  labels:
    environment: $env
    purpose: custom
EOF
  
  echo "Cluster '$name' added to $CONFIG_FILE"
}

function remove_cluster() {
  local name=$1
  
  if [[ -z "$name" ]]; then
    echo "Error: Missing cluster name to remove"
    echo "Usage: $0 --remove NAME"
    exit 1
  fi
  
  # Check if cluster exists
  if ! grep -q "^- name: $name$" "$CONFIG_FILE"; then
    echo "Error: Cluster '$name' not found in $CONFIG_FILE"
    exit 1
  fi
  
  # Create a temporary file
  TMP_FILE=$(mktemp)
  
  # Find line number of cluster definition
  LINE_NUM=$(grep -n "^- name: $name$" "$CONFIG_FILE" | cut -d: -f1)
  
  # Calculate line ranges to keep
  START_LINE=$((LINE_NUM - 1))
  
  # Extract all lines to delete (from name line to next cluster or EOF)
  END_LINE=$(tail -n +$LINE_NUM "$CONFIG_FILE" | grep -n "^- name:" | head -1 | cut -d: -f1)
  
  if [[ -z "$END_LINE" ]]; then
    # No more clusters found, delete to EOF
    head -n $START_LINE "$CONFIG_FILE" > "$TMP_FILE"
  else
    # Delete to next cluster
    END_LINE=$((LINE_NUM + END_LINE - 1))
    head -n $START_LINE "$CONFIG_FILE" > "$TMP_FILE"
    tail -n +$END_LINE "$CONFIG_FILE" >> "$TMP_FILE"
  fi
  
  # Replace original file
  mv "$TMP_FILE" "$CONFIG_FILE"
  
  echo "Cluster '$name' removed from $CONFIG_FILE"
}

function sync_root_app() {
  echo "Syncing root application to propagate changes..."
  if command -v argocd &> /dev/null; then
    argocd app sync root-appset
  else
    echo "ArgoCD CLI not found. Please sync manually or install the ArgoCD CLI."
    echo "You can install it with: curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
    echo "chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd"
  fi
}

# Parse command-line arguments
if [[ $# -eq 0 ]]; then
  show_help
fi

SYNC_AFTER=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      ;;
    -l|--list)
      list_clusters
      shift
      ;;
    -a|--add)
      add_cluster "$2" "$3" "$4"
      shift 4
      ;;
    -r|--remove)
      remove_cluster "$2"
      shift 2
      ;;
    -s|--sync)
      SYNC_AFTER=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

if [[ "$SYNC_AFTER" = true ]]; then
  sync_root_app
fi
