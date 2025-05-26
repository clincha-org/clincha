# Traefik


## Install

1. Add the helm repository and update it
   ```bash
   helm repo add traefik https://traefik.github.io/charts
   helm repo update
   ```
2. Install Traefik
   ```bash
   helm install traefik traefik/traefik --namespace traefik --values traefik-values.yml --create-namespace
   ```

Additional settings can be configured using the [Helm values](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml).