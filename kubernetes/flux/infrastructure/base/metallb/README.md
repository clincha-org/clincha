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

   > **All-control-plane clusters:** MetalLB v0.15+ will not L2-announce a VIP
   > from any node carrying the `node.kubernetes.io/exclude-from-external-load-balancers`
   > label, which kubeadm adds to every control-plane node. On a cluster where
   > all nodes are control-plane (Hawkfield, London), this leaves no eligible
   > speaker and every LoadBalancer VIP goes dark. The label is stripped
   > automatically by the **"Allow LoadBalancer announcement from control-plane
   > nodes"** play in `Ansible/kubernetes.yml`, which re-runs on every cluster
   > rebuild / Kubespray upgrade. See [clincha-org/clincha#294](https://github.com/clincha-org/clincha/issues/294).

2. Install using Helm
    ```bash
    helm repo add metallb https://metallb.github.io/metallb
    helm repo update
    helm install metallb metallb/metallb --namespace metallb --create-namespace
    ```
   _Additional Helm values can be set using
   the [chart's values](https://github.com/metallb/metallb/blob/main/charts/metallb/values.yaml)_

3. Create the IP pools
    ```bash
   kubectl apply -f ./pools.yml 
   ```

4. Test using the NGINX deployment and service provided
    ```bash
   kubectl apply -f ./test-nginx.yml 
   ```
   Navigate to the IP address given in the EXTERNAL-IP section for nginx after running `kubectl get service`

5. Uninstall
    ```bash
    helm uninstall metallb -n metallb
    kubectl delete namespace metallb
    ```
