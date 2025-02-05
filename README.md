helm install rancher rancher-stable/rancher  --namespace cattle-system --set hostname=rancher.localhost --set bootstrapPassword=admin --set replicas=1

helm uninstall rancher rancher-stable/rancher --namespace cattle-system

kubectl port-forward -n cattle-system service/rancher 8443:443