# MetalLB

Bare metal load balancer used to give LoadBalanced IP addresses to services.

## Install

Do the following from a kubernetes master as the user `kubernetes`

1. Set strictARP to `true`
   ```bash
   kubectl get configmap kube-proxy -n kube-system -o yaml | \
   sed -e "s/strictARP: false/strictARP: true/" | \
   kubectl apply -f - -n kube-system
   ```
2. Install using Helm
    ```bash
    helm repo add metallb https://metallb.github.io/metallb
    helm repo update
    helm install metallb metallb/metallb --namespace metallb --create-namespace
    ```
3. Create the IP pools
    ```bash
   kubectl apply -f ./pools.yml 
   ```

4. Test using the NGINX deployment and service provided
    ```bash
   kubectl apply -f ./test-nginx.yml 
   ```
   Navigate to the IP address given in the EXTERNAL-IP section for nginx after running `kubectl get service`

_Additional Helm values can be set using
the [chart's values](https://github.com/metallb/metallb/blob/main/charts/metallb/values.yaml)_
