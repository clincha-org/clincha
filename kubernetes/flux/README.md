# Flux

Using Flux to try and automate the deployment of applications. I'm going to see if it's possible to bootstrap most of the cluster.

https://fluxcd.io/flux/installation/bootstrap/github/

Generate an SSH key and install a deployment key in the GitHub repository to allow Flux to push changes to the repository.

## Bootstrap

Start minikube and install open-iscsi for Longhorn.

### Development

```bash
minikube start -p dev --nodes 3 --driver=docker --cpus=2 --memory=4gb --subnet=10.2.1.0/24;
```

```bash
minikube ssh --profile dev -n dev "sudo apt-get update;sudo apt-get install -y open-iscsi nfs-common";
minikube ssh --profile dev -n dev-m02 "sudo apt-get update;sudo apt-get install -y open-iscsi nfs-common";
minikube ssh --profile dev -n dev-m03 "sudo apt-get update;sudo apt-get install -y open-iscsi nfs-common";
```

```bash
kubectl config use-context dev
```

Open a tunnel to the minikube cluster so we can access services like the Longhorn UI

```bash
minikube --profile dev tunnel
```

### Create the decryption secret

Download the sops key from BitWarden and import it.

```bash
gpg --import sops.asc
```

Download the SSH key from BitWarden and save it to `/home/clincha/.ssh/flux` and set the permissions

```bash
chmod 600 /home/clincha/.ssh/flux
```

Set the following environment variables so we can create the kubernetes secret

```bash
export KEY_NAME="hawkfield.clinch-home.com"
export KEY_COMMENT="flux secrets"
export KEY_FP=76AF39813C2297E8F98C542D42436A07A9BA1DE0
```

Create the kubernetes secret from the key

```bash
kubectl create namespace flux-system
gpg --export-secret-keys --armor "${KEY_FP}" |
kubectl create secret generic sops-gpg \
--namespace=flux-system \
--from-file=sops.asc=/dev/stdin
```

### Flux

```bash
flux check --pre
```

#### dev

```bash
flux bootstrap git --silent \
  --url=ssh://git@github.com/clincha-org/clincha \
  --context=dev \
  --branch=master \
  --private-key-file=/home/clincha/.ssh/flux \
  --path=kubernetes/flux/clusters/dev
```

#### Hawkfield

```bash
flux bootstrap git --silent \
  --url=ssh://git@github.com/clincha-org/clincha \
  --branch=master \
  --private-key-file=/home/clincha/.ssh/flux \
  --path=kubernetes/flux/clusters/hawkfield
```

## Uninstall

### Uninstall Flux

dev

```bash
kubectl config use-context dev
flux uninstall --namespace=flux-system --silent
```

hawkfield

```bash
kubectl config use-context hawkfield
flux uninstall --namespace=flux-system --silent
```

### Delete the minikube clusters

#### Development

```bash
minikube delete --profile dev
```

## Secrets

https://fluxcd.io/flux/guides/mozilla-sops/

You can use the public key to encrypt files locally. Make sure you are in the
`/kubernetes/flux` directory which contains the `.sops.yaml` file.

```bash
gpg --import ./clusters/hawkfield/.sops.pub.asc
```

To encrypt a file, for example `cloudflare-secret.yaml`:

```bash
sops --encrypt --in-place cloudflare-secret.yaml
```
