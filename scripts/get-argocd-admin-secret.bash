kubectl config use-context kind01
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode

# Port-forward the argocd server
kubectl port-forward svc/argocd-server 8080:80 -n argocd --address 0.0.0.0