# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal cloud infrastructure spanning Bristol (Hawkfield) and London sites. Stack: Proxmox hypervisors → Packer templates → Terraform VMs → Ansible configuration → Kubernetes (Kubespray) → Flux CD GitOps.

## Sites

- **Hawkfield**: Bristol location
- **London**: London location

Inventory lookup:
```bash
ansible-inventory -i inventory/hawkfield.proxmox.yml --list
ansible-inventory -i inventory/london.proxmox.yml --list
```

## Common Commands

### Ansible

All Ansible commands run from the `Ansible/` directory. Python 3.13, ansible-core 2.17.14 (pinned for Kubespray compatibility).

```bash
# Install Python dependencies
pip install -r Ansible/requirements.txt

# Install Galaxy collections
ansible-galaxy install -r Ansible/galaxy-requirements.yml

# Lint (production profile, strict)
ansible-lint Ansible/

# Run playbooks
ansible-playbook -i inventory/hawkfield.proxmox.yml Ansible/base.yml
ansible-playbook -i inventory/hawkfield.proxmox.yml Ansible/kubernetes.yml
```

### Terraform

Working directories: `terraform/hawkfield/`, `terraform/london/`, `terraform/kubernetes/`. Backend is MinIO (S3-compatible).

```bash
terraform -chdir=terraform/hawkfield init
terraform -chdir=terraform/hawkfield plan
terraform -chdir=terraform/hawkfield apply
```

### Packer

```bash
packer build packer/ubuntu2404/main.pkr.hcl
```

### Linting

- **ansible-lint**: Production profile, strict mode (`.ansible-lint.yaml`)
- **yamllint**: Custom config in `.yamllint` — disables new-line-at-end-of-file, empty-lines, and comments rules

## Architecture

### Ansible (`Ansible/`)

- **Playbooks**: `base.yml` (OS config), `kubernetes.yml` (K8s + Flux), `flux.yml` (GitOps bootstrap), `update-k8s.yml`, `update-proxmox.yml`, `proxmox.yml`
- **Roles**: `base/`, `users/`, `sudoers/`, `helm/`
- **Inventory**: Dynamic Proxmox-based (`inventory/hawkfield.proxmox.yml`, `inventory/london.proxmox.yml`)
- **Group vars**: `group_vars/all.yml`, `group_vars/hawkfield.yml`, `group_vars/london.yml`
- Kubespray v2.29.0 (installed via Galaxy as a collection)

### Kubernetes (`kubernetes/flux/`)

Flux CD GitOps structure:
- `clusters/` — per-cluster bootstrap configs (dev, hawkfield, london)
- `infrastructure/` — shared base + per-site (monitoring, networking, storage)
- `applications/` — workloads (Factorio, Homepage, Elastic Finance, etc.)
- Secrets encrypted with SOPS (GPG-based)

### Terraform (`terraform/`)

- `modules/ubuntu-server/` — reusable Proxmox VM module
- Per-site directories for hawkfield, london, kubernetes

### CI/CD (`.github/workflows/`)

GitHub Actions workflows use Tailscale to connect to internal infrastructure. See [`.github/workflows/README.md`](.github/workflows/README.md) for full documentation. Key workflows:
- `ansible-lint.yaml` — lint on PRs
- `ansible-base.yaml` — base config deployment (hourly + on merge)
- `ansible-update-proxmox.yaml` — daily Proxmox updates (3 AM)
- `ansible-proxmox.yaml` — Proxmox role/ACL/token config (manual)
- `ansible-proxmox-bootstrap.yaml` — initial Proxmox setup (manual)
- `packer.yaml` — VM template builds (weekly + on merge)
- `terraform-plan.yaml` — plan on PRs for hawkfield + london
- `terraform.yaml` — plan/apply for hawkfield
- `cluster-rebuild.yaml` — full destroy/provision/configure (manual)

## Conventions

- Do not credit Claude in commits, PRs, or comments (no Co-Authored-By, no "Generated with Claude Code")
- Be concise in commit messages and PR descriptions
- Always branch from master for each change; do not reuse branches
- Secrets managed via Ansible Vault and SOPS — never commit plaintext secrets
