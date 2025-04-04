# Local setup notes

## Setup VM
- Setup Ubuntu 24.04 server VM on QEMU/KVM Virtual Machine Manager

## Setup MicroK8s
- Enable microk8s as part of server installation step or install manually
- Add user to microk8s group and either reboot or run `newgrp microk8s`
- Install kubectl snap
- Export microk8s config to `~/.kube/config` and make sure user has access to this.

## Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```