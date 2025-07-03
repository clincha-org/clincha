# Monitoring

https://technotim.live/posts/kube-grafana-prometheus/

https://github.com/prometheus-community/helm-charts

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

```bash
echo -n 'adminuser' > ./admin-user # clincha
echo -n 'p@ssword!' > ./admin-password # Bitwarden (grafana)
```

```bash
kubectl create namespace monitoring
```

```bash
kubectl create secret generic grafana-admin-credentials --from-file=./admin-user --from-file=admin-password -n monitoring
```

```bash
helm install -n monitoring prometheus prometheus-community/kube-prometheus-stack -f values.yaml
```