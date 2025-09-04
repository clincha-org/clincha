# Flux

Using Flux to try and automate the deployment of applications. I'm going to see if it's possible to bootstrap most of the cluster.

https://fluxcd.io/flux/installation/bootstrap/github/

Generate an SSH key and install a deployment key in the GitHub repository to allow Flux to push changes to the repository.

```bash
flux check --pre
```

```bash
flux bootstrap git \
  --url=ssh://git@github.com/clincha-org/clincha \
  --branch=master \
  --private-key-file=/home/clincha/.ssh/flux \
  --path=clusters/hawkfield
```

## Secrets

https://fluxcd.io/flux/guides/mozilla-sops/

```bash
export KEY_NAME="hawkfield.clinch-home.com"
export KEY_COMMENT="flux secrets"
export KEY_FP=76AF39813C2297E8F98C542D42436A07A9BA1DE0
```

```bash
gpg --import ./clusters/hawkfield/.sops.pub.asc
```