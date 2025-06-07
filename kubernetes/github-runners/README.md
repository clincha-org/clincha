# GitHub Runners on Kubernetes

https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller

## Install

1. Install the Actions Runner Controller Helm chart:
   ```bash
   helm install "github-runners" --namespace "github-runners" --create-namespace oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
   ```

2. Create a Kubernetes secret with the GitHub pem key encoded in base64. These details can be found in BitWarden.

3. Install the scale set:
   ```bash
   helm install "github-runners-clincha" --namespace "github-runners-clincha" --create-namespace --values scale-set-values.yml oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
   ```