# Install

There are two components to the installation. The operator and the components. The orchestrator is responsible for managing deployments and the components provide the functionality.

## The operator

Documentation: https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/install-using-helm-chart

```bash
    helm repo add elastic https://helm.elastic.co
    helm repo update
    helm install elastic-operator elastic/eck-operator -n elastic-system --create-namespace
```

## The components

Documentation: https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/manage-deployments

### Elastic Search

https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/elasticsearch-deployment-quickstart

Password:

```bash
  kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'
```

TLS Certificate:

```bash
  kubectl get secret quickstart-es-http-certs-public -o go-template='{{index .data "tls.crt" | base64decode }}'
```

### Kibana

https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/kibana-instance-quickstart

Password:

```bash
  kubectl get secret elasticsearch-es-elastic-user -n elastic-stack -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

Make sure to use **HTTPS** to get to the URL. Port is **5601**.

### Logstash

https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/logstash

### Beats

https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/beats

## Fleet

```bash
helm upgrade --install eck-stack-with-fleet elastic/eck-stack --values eck-with-fleet-values.yaml -n elastic-stack --create-namespace
```