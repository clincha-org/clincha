# cert-manager

Simple certificate management for Kubernetes.

## Install

1. Add the Helm chart
    ```bash
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    ```

2. Install cert-manager
    ```bash
    helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --values cert-manager-values.yml
    ```

3. Apply the Cloudflare token secret
    ```bash
    kubectl apply -f issuer-secret.yml
    ```

4. Apply the certificate issuers
    ```bash
    kubectl apply -f issuers.yml
    ```

Additional settings can be configured on the [Helm chart](https://artifacthub.io/packages/helm/cert-manager/cert-manager)