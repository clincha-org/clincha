# Terraform

## Kubernetes hosts

- Create a secret file `providers.tfvars` which has the token for the proxmox terraform user.
- Run it using

```bash
terraform init
terraform apply --var-file=providers.tfvars
```