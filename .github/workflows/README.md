# CI/CD Workflows

All workflows run on GitHub Actions and connect to internal infrastructure via [Tailscale](https://tailscale.com/). Cluster rebuild requires approval through the `production` GitHub environment. Terraform apply does not — its plan is reviewed on the PR, and merging to `master` is the approval.

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
| **Kubernetes Validate** | `k8s-validate.yaml` | PR (paths: `kubernetes/**`), manual | N/A | `kubectl kustomize` + `kubeconform` over every overlay, plus `yamllint` on changed YAML |

`k8s-validate` builds all 62 kustomization directories under `kubernetes/flux/` and
schema-checks the output. `-ignore-missing-schemas` lets the Flux CRs through and
`-skip Secret` lets the SOPS blobs through — `-strict` would otherwise reject their
`sops` key as an extra property.

The `yamllint` job lints only the YAML a PR changed, against the repo `.yamllint`.
A whole-tree run currently reports ~2,900 errors (the bulk in the generated
`gotk-components.yaml`), so gating on the full repo would fail every PR regardless of
its contents.

### Deploy on Merge

These run when changes are pushed to `master` (i.e. a PR is merged).

| Workflow | File | Triggers | Sites | What it does |
|----------|------|----------|-------|-------------|
| **Packer Build** | `packer.yaml` | Push to master (paths: `packer/**`), weekly Sunday 04:00 UTC, manual | hawk01–03, lon01 | Builds Ubuntu 24.04 VM templates on all Proxmox nodes (matrix build, one per host) |
| **Terraform Apply** | `terraform.yaml` | Push to master (paths: `terraform/**`), manual | Hawkfield, London | Plans then applies Terraform for both sites (matrix). Applies unattended — `terraform-plan.yaml` already posted the plan on the PR |
| **Ansible Base** | `ansible-base.yaml` | Push to master (paths: `Ansible/**`), hourly, manual | Hawkfield, London (parallel) | Runs `base.yml` playbook — user accounts, sudoers, base packages |
| **Proxmox Config** | `ansible-proxmox.yaml` | Push to master (paths: `Ansible/proxmox.yml`), hourly, manual | Hawkfield, London (parallel) | Configures Proxmox API roles, users, and ACLs via `proxmox.yml` playbook |

### Scheduled Maintenance

| Workflow | File | Schedule | Sites | What it does |
|----------|------|----------|-------|-------------|
| **Update Proxmox** | `ansible-update-proxmox.yaml` | Daily 03:00 UTC, manual | Hawkfield, London (parallel) | Runs `update-proxmox.yml` — apt upgrades on Proxmox hosts (independent per site) |
| **Renovate** | `renovate.yaml` | Daily 06:00 UTC, manual | N/A | Proposes dependency updates as PRs across images, Helm charts, pip, github-actions and terraform |

Renovate is configured by `/renovate.json` at the repo root and owns every ecosystem
in the repo: container images and Helm charts under `kubernetes/flux/`, plus pip
(`Ansible/requirements.txt`), github-actions and terraform. Dependabot used to own
the latter three and was removed once Renovate took them over.

Minor, patch and digest bumps auto-merge once CI is green and the release is three
days old; majors are left for review. Terraform is excluded from auto-merge because
CI only plans, so a provider bump that changes real infrastructure at apply time
gets read first. Merging a Renovate PR deploys it — Flux reconciles within 1–2
minutes.

Renovate pushes with a PAT rather than `GITHUB_TOKEN`, so its PRs trigger workflows
normally and `terraform-plan.yaml` runs a real plan on a provider bump. That PAT
needs the **Workflows** permission to touch `.github/workflows/**`; without it,
github-actions bumps to workflow files fail the branch push with a 403.

`clincha/media` runs its own copy of this workflow against its own `renovate.json`.
The two are separate because a fine-grained PAT has a single resource owner and
cannot span an org-owned and a user-owned repo.

Run manually with **dryRun: true** to see what it would propose without opening
anything.

### Manual Operations

These are triggered via `workflow_dispatch` only (Actions tab > Run workflow).

| Workflow | File | Sites | What it does |
|----------|------|-------|-------------|
| **Proxmox Bootstrap** | `ansible-proxmox-bootstrap.yaml` | Per `inventory/bootstrap.yml` | Initial Proxmox setup. Uses root password (not SSH key). Run once per new node |
| **Cluster Rebuild** | `cluster-rebuild.yaml` | Hawkfield | Full cluster teardown and rebuild: `terraform destroy` → `terraform apply` → `ansible-playbook kubernetes.yml`. Requires `production` approval before the destroy |

## Concurrency Groups

Workflows use concurrency groups to prevent dangerous parallel runs:

| Group | Workflows | Behaviour |
|-------|-----------|-----------|
| `cluster-{site}` | terraform.yaml, ansible-base.yaml | Per-site — each site's job serialises with that site's terraform run |
| `cluster-hawkfield` | cluster-rebuild.yaml | Serialises the rebuild against Hawkfield's other cluster work |
| `terraform-plan-{PR}` | terraform-plan.yaml | Per-PR, cancels in-progress — only latest plan matters |
| `packer-{host}` | packer.yaml | Per-host — prevents parallel builds on the same Proxmox node |
| `{workflow name}` | ansible-update-proxmox, ansible-proxmox, ansible-proxmox-bootstrap | Serialised per workflow |

### Concurrency and the `production` gate

A job acquires its concurrency group *before* it waits on an environment gate, so a job
that declares both holds the group for as long as nobody approves it — every later run
in that group pends until it is cancelled ([#399](https://github.com/clincha-org/clincha/issues/399)).
No job in this repo may declare `environment:` and `concurrency:` together.

`terraform.yaml` has no gate at all. `terraform-plan.yaml` posts the plan on the PR, so
approving the merge approves the apply; a second click per run only earned unattended
runs a lock they held for days.

`cluster-rebuild.yaml` keeps the `production` gate — it destroys a live cluster on a
manual dispatch, with no reviewed plan behind it. The gate sits in a group-less `approve`
job that `destroy` `needs`, so an unapproved rebuild holds nothing. The three working jobs
hold `cluster-hawkfield` individually rather than the whole run, which leaves the group
briefly free between them: an hourly `ansible-base` run can slip into a gap and fail
against half-rebuilt hosts. That is preferred over a workflow-level group, which puts the
gate and the lock back in the same run.

## Secrets

All secrets are stored in GitHub repository settings.

| Secret | Purpose | Used by |
|--------|---------|---------|
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth client ID | All workflows except ansible-lint |
| `TS_OAUTH_SECRET` | Tailscale OAuth secret | All workflows except ansible-lint |
| `ANSIBLE_VAULT_PASSWORD` | Decrypts Ansible Vault-encrypted vars | ansible-base, ansible-update-proxmox, ansible-proxmox, cluster-rebuild |
| `ANSIBLE_PRIVATE_KEY` | SSH private key (ed25519) for Ansible | ansible-base, ansible-update-proxmox, ansible-proxmox, cluster-rebuild |
| `RUSTFS_SECRET_KEY` | Terraform state backend (RustFS/S3) | terraform, terraform-plan, cluster-rebuild |
| `PROXMOX_TOKEN_HAWKFIELD_ANSIBLE` | Proxmox API token for Ansible (Bristol) | ansible-base, ansible-proxmox |
| `PROXMOX_TOKEN_LONDON_ANSIBLE` | Proxmox API token for Ansible (London) | ansible-base, ansible-proxmox |
| `PROXMOX_TOKEN_HAWKFIELD_PACKER` | Proxmox API token for Packer (Bristol) | packer |
| `PROXMOX_TOKEN_LONDON_PACKER` | Proxmox API token for Packer (London) | packer |
| `PROXMOX_TOKEN_HAWKFIELD_TERRAFORM` | Proxmox API token for Terraform (Bristol) | terraform, terraform-plan, cluster-rebuild |
| `PROXMOX_TOKEN_LONDON_TERRAFORM` | Proxmox API token for Terraform (London) | terraform, terraform-plan, cluster-rebuild |
| `PACKER_SSH_PASSWORD` | SSH password for Packer VM provisioning | packer |
| `PROXMOX_ROOT_PASSWORD` | Root password for bootstrap | ansible-proxmox-bootstrap |
| `GH_PAT` | GitHub Personal Access Token | ansible-proxmox-bootstrap |
| `RENOVATE_TOKEN` | Fine-grained PAT, this repo only, Contents + Pull requests + Issues read/write | renovate |

All three permissions are required. **Issues** is the non-obvious one: Renovate's
repo-init GraphQL query reads `repository.issues` unconditionally, so without it the
run dies at startup with an opaque `platform-unknown-error` — the underlying
`FORBIDDEN` on the `issues` field is only visible at debug log level. Write, not just
read, because `dependencyDashboard` needs to open and update its issue.

`RENOVATE_TOKEN` is deliberately not `GH_PAT`: that one is a classic token carrying
`admin:org`, `delete_repo` and `workflow`, far beyond what Renovate needs. It also
omits `workflow` scope, so Renovate cannot write under `.github/workflows/`.

## Known Gaps

Tracked in the [CI/CD Improvements](https://github.com/clincha-org/clincha/milestone/6) milestone:

- **Boilerplate repetition** — mostly addressed by the composite actions in [`.github/actions/`](../actions): `ansible-setup` (Python, pip, galaxy, vault, SSH key) and `terraform-setup` (Tailscale, RustFS check, setup-terraform). Ansible workflows still declare their own Tailscale step. [#215](https://github.com/clincha-org/clincha/issues/215)
