# Terraform

## Kubernetes hosts

- Create a secret file `providers.tfvars` which has the token for the proxmox terraform user.
- Run it using

```bash
terraform init
terraform apply --var-file=providers.tfvars
```
## Uptime Kuma

`terraform/uptime-kuma` manages the monitors, the Telegram notification and the
status page. Adding a service is one entry in the `monitors` map in `main.tf`.

It has its own workflow rather than joining the matrix in `terraform.yaml`:
that workflow passes `-var="pm_api_token_secret"` to every stack, and Terraform
errors on a `-var` it has no declaration for.

The admin user it authenticates as is created by a Flux Job
(`kubernetes/flux/infrastructure/hawkfield/uptime-kuma/admin-bootstrap-job.yml`),
not by hand — Uptime Kuma has no env-based bootstrap, so the Job calls the
Socket.IO `setup` event. Re-running is safe; the server rejects a second setup
once a user exists.

Credentials live in Bitwarden (`Uptime Kuma admin`,
`Uptime Kuma Telegram notification`) and as repository secrets
`UPTIME_KUMA_ADMIN_PASSWORD`, `UPTIME_KUMA_TELEGRAM_BOT_TOKEN` and
`UPTIME_KUMA_TELEGRAM_CHAT_ID`.
