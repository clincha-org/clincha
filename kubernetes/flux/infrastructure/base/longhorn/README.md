# Longhorn

Storage provider for Kubernetes

## Install

1. Annotate the nodes so that default disks are created
   ```bash
   kubectl patch node k8s-master-1 --type merge --patch-file ./node-disks.yml
   kubectl patch node k8s-master-2 --type merge --patch-file ./node-disks.yml
   kubectl patch node k8s-master-3 --type merge --patch-file ./node-disks.yml
   ```

2. Add the helm repository & install
    ```bash
    helm repo add longhorn https://charts.longhorn.io
    helm repo update
    helm install longhorn longhorn/longhorn --namespace longhorn --create-namespace --values values.yml
    ```

3. Apply the backup CRDs
   ```bash
   kubectl apply -f ./backup-secret.yml
   kubectl apply -f ./backup-jobs.yml
   ```

3. Apply the storage classes
   ```bash
   kubectl apply -f ./storage-class.yml
   ```

## Upgrade

 ```bash
   helm upgrade longhorn longhorn/longhorn --namespace longhorn --values values.yml
 ```