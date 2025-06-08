- Ensure the operator is installed on the cluster
- Install an eck-managed Elasticsearch and Kibana

```bash
  helm upgrade --install elastic-finance elastic/eck-stack -n elastic-finance --create-namespace --values values.yml
```

- Get the password for the elastic user

```bash
  kubectl get secret elasticsearch-es-elastic-user -n elastic-finance -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```