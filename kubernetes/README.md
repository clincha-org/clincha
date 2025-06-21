# Kubernetes

## Redeploy

- Terraform apply
- Ansible playbook `kubernetes.yml`
- Copy the `kubeconfig` file to the local machine and to GitHub secrets (CHANGE THE IP ADDRESS)
- Apply the GitHub runners scale set
- [Deploy MetalLB](https://github.com/clincha-org/clincha/actions/workflows/k8s-metallb.yaml)
- [Deploy cert-manager](https://github.com/clincha-org/clincha/actions/workflows/k8s-certificate-manager.yaml)
- [Deploy Traefik](https://github.com/clincha-org/clincha/actions/workflows/k8s-traefik.yaml)
- [Deploy Longhorn](https://github.com/clincha-org/clincha/actions/workflows/k8s-longhorn.yaml)
- Deploy applications
  - media
  - factorio
  - homepage