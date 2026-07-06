# CI/CD Workflows

All workflows run on GitHub Actions and connect to internal infrastructure via [Tailscale](https://tailscale.com/). Destructive operations (terraform apply, cluster rebuild) require approval through the `production` GitHub environment.

## Infrastructure Lifecycle

When setting up a new site from scratch, run workflows in this order:

```
1. ansible-proxmox-bootstrap  (initial Proxmox host setup — root password auth)
2. ansible-proxmox             (configure Proxmox roles, ACLs, API tokens)
3. packer                      (build Ubuntu 24.04 VM templates on each node)
4. terraform                   (provision VMs from templates)
5. ansible-base                (base OS config — users, sudoers, packages)
6. cluster-rebuild             (deploy Kubernetes via Kubespray + bootstrap Flux CD)
```

Step 1 is manual one-time setup. Steps 2–5 run automatically on merge to master. Step 6 is manual.

After initial setup, day-to-day changes flow through PRs: lint and terraform plan run on the PR, then deploy workflows trigger on merge.

## Workflow Reference

### PR Checks

These run automatically on pull requests to validate changes before merge.

| Workflow | File | Triggers | Sites | What it does |
|----------|------|----------|-------|-------------|
| **Ansible Lint** | `ansible-lint.yaml` | PR (paths: `Ansible/**`), manual | N/A | Lints all Ansible code with `ansible-lint --strict` |
| **Terraform Plan (PR)** | `terraform-plan.yaml` | PR (paths: `terraform/**`) | Hawkfield, London | Runs `terraform plan` for both sites and posts results as a PR comment |

### Deploy on Merge

These run when changes are pushed to `master` (i.e. a PR is merged).

| Workflow | File | Triggers | Sites | What it does |
|----------|------|----------|-------|-------------|
| **Packer Build** | `packer.yaml` | Push to master (paths: `packer/**`), weekly Sunday 04:00 UTC, manual | hawk01–03, lon01 | Builds Ubuntu 24.04 VM templates on all Proxmox nodes (matrix build, one per host) |
| **Terraform Apply** | `terraform.yaml` | Push to master (paths: `terraform/**`), manual | Hawkfield, London | Plans then applies Terraform for both sites (matrix). Apply job requires `production` environment approval |
| **Ansible Base** | `ansible-base.yaml` | Push to master (paths: `Ansible/**`), hourly, manual | Hawkfield only | Runs `base.yml` playbook — user accounts, sudoers, base packages |
| **Proxmox Config** | `ansible-proxmox.yaml` | Push to master (paths: `Ansible/proxmox.yml`), hourly, manual | Hawkfield, London (parallel) | Configures Proxmox API roles, users, and ACLs via `proxmox.yml` playbook |

### Scheduled Maintenance

| Workflow | File | Schedule | Sites | What it does |
|----------|------|----------|-------|-------------|
| **Update Proxmox** | `ansible-update-proxmox.yaml` | Daily 03:00 UTC, manual | Hawkfield, London (parallel) | Runs `update-proxmox.yml` — apt upgrades on Proxmox hosts (independent per site) |

### Manual Operations

These are triggered via `workflow_dispatch` only (Actions tab > Run workflow).

| Workflow | File | Sites | What it does |
|----------|------|-------|-------------|
| **Proxmox Bootstrap** | `ansible-proxmox-bootstrap.yaml` | Per `inventory/bootstrap.yml` | Initial Proxmox setup. Uses root password (not SSH key). Run once per new node |
| **Cluster Rebuild** | `cluster-rebuild.yaml` | Choose: hawkfield or london | Full cluster teardown and rebuild: `terraform destroy` → `terraform apply` → `ansible-playbook kubernetes.yml`. Destroy requires `production` approval |

## Concurrency Groups

Workflows use concurrency groups to prevent dangerous parallel runs:

| Group | Workflows | Behaviour |
|-------|-----------|-----------|
| `cluster-{site}` | terraform.yaml | Per-site — hawkfield and london apply independently |
| `cluster-hawkfield` | ansible-base.yaml | Serialised with any hawkfield terraform run |
| `cluster-{input}` | cluster-rebuild.yaml | Per-cluster — hawkfield and london can run independently |
| `terraform-plan-{PR}` | terraform-plan.yaml | Per-PR, cancels in-progress — only latest plan matters |
| `packer-{host}` | packer.yaml | Per-host — prevents parallel builds on the same Proxmox node |
| `{workflow name}` | ansible-update-proxmox, ansible-proxmox, ansible-proxmox-bootstrap | Serialised per workflow |

## Secrets

All secrets are stored in GitHub repository settings.

| Secret | Purpose | Used by |
|--------|---------|---------|
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth client ID | All workflows except ansible-lint |
| `TS_OAUTH_SECRET` | Tailscale OAuth secret | All workflows except ansible-lint |
| `ANSIBLE_VAULT_PASSWORD` | Decrypts Ansible Vault-encrypted vars | ansible-base, ansible-update-proxmox, ansible-proxmox, cluster-rebuild |
| `ANSIBLE_PRIVATE_KEY` | SSH private key (ed25519) for Ansible | ansible-base, ansible-update-proxmox, ansible-proxmox, cluster-rebuild |
| `MINIO_SECRET_KEY` | Terraform state backend (MinIO/S3) | terraform, terraform-plan, cluster-rebuild |
| `PROXMOX_TOKEN_HAWKFIELD_ANSIBLE` | Proxmox API token for Ansible (Bristol) | ansible-proxmox |
| `PROXMOX_TOKEN_LONDON_ANSIBLE` | Proxmox API token for Ansible (London) | ansible-proxmox |
| `PROXMOX_TOKEN_HAWKFIELD_PACKER` | Proxmox API token for Packer (Bristol) | packer |
| `PROXMOX_TOKEN_LONDON_PACKER` | Proxmox API token for Packer (London) | packer |
| `PROXMOX_TOKEN_HAWKFIELD_TERRAFORM` | Proxmox API token for Terraform (Bristol) | terraform, terraform-plan, cluster-rebuild |
| `PROXMOX_TOKEN_LONDON_TERRAFORM` | Proxmox API token for Terraform (London) | terraform, terraform-plan, cluster-rebuild |
| `PACKER_SSH_PASSWORD` | SSH password for Packer VM provisioning | packer |
| `PROXMOX_ROOT_PASSWORD` | Root password for bootstrap | ansible-proxmox-bootstrap |
| `GH_PAT` | GitHub Personal Access Token | ansible-proxmox-bootstrap |

## Known Gaps

Tracked in the [CI/CD Improvements](https://github.com/clincha-org/clincha/milestone/6) milestone:

- **ansible-base is hawkfield-only** — the hourly base config reconciliation only targets hawkfield. London base config must be applied manually. [#214](https://github.com/clincha-org/clincha/issues/214)
- **Boilerplate repetition** — mostly addressed by the composite actions in [`.github/actions/`](../actions): `ansible-setup` (Python, pip, galaxy, vault, SSH key) and `terraform-setup` (Tailscale, MinIO check, setup-terraform). Ansible workflows still declare their own Tailscale step. [#215](https://github.com/clincha-org/clincha/issues/215)
