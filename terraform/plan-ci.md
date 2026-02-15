# Plan: Terraform Plan on Pull Requests

## Goal

Run `terraform plan` automatically on PRs that touch `terraform/**`, posting the plan output as a PR comment so reviewers can see what will change before merging.

## Problem

The current `terraform.yaml` workflow:
- Only triggers on push to `master` (too late — changes are already merged)
- Runs on self-hosted runners (`github-runners-clincha`) inside the network
- References `terraform/kubernetes` which no longer exists (now `hawkfield/` and `london/`)
- Has no PR feedback loop

## Approach

### Network Access via WireGuard VPN

Terraform needs to reach two internal services:
- **MinIO** (10.1.2.10:9000) — S3 backend for state
- **Proxmox** (10.1.2.11:8006) — provider API for planning

Since these are inside the home network, the GitHub Actions runner must connect via WireGuard VPN to the router.

**Required GitHub Secrets:**
| Secret | Purpose |
|--------|---------|
| `WG_PRIVATE_KEY` | WireGuard private key for the CI peer |
| `WG_PEER_PUBLIC_KEY` | Router's WireGuard public key |
| `WG_ENDPOINT` | Router's public IP:port (e.g. `203.0.113.1:51820`) |
| `WG_ADDRESS` | VPN IP for the CI peer (e.g. `10.1.2.200/24`) |
| `WG_ALLOWED_IPS` | Subnet to route (e.g. `10.1.2.0/24`) |
| `MINIO_SECRET_KEY` | MinIO secret for S3 backend (already exists) |
| `PM_TF_API_TOKEN_SECRET` | Proxmox API token secret (already exists) |

**Router setup needed:**
- Add a new WireGuard peer for the CI runner on the router
- Assign it a static VPN IP (e.g. 10.1.2.200)
- Allow access to 10.1.2.10 (MinIO) and 10.1.2.11 (Proxmox)

### Workflow Design

```
PR opened/updated → terraform-plan.yaml triggers
  ├─ Setup WireGuard VPN tunnel
  ├─ Install Terraform
  ├─ For each site (hawkfield, london):
  │   ├─ terraform init (with MinIO backend)
  │   ├─ terraform plan (read-only, no apply)
  │   └─ Capture plan output
  ├─ Post combined plan as PR comment
  └─ Tear down VPN
```

### Key Decisions

1. **GitHub-hosted runners + VPN** rather than self-hosted runners
   - More reliable (no dependency on internal runner availability)
   - Easier to maintain
   - VPN gives the same network access

2. **Plan only, never apply** on PRs
   - Apply remains manual or via the existing master-push workflow
   - Safe for review purposes

3. **PR comment output** using `actions/github-script`
   - Updates the same comment on re-push (no spam)
   - Collapsible `<details>` blocks for each site

4. **Both sites planned** (hawkfield + london)
   - Matrix strategy so they run in parallel
   - Each has its own state file and providers.tfvars

### What Needs Doing on the Router

Before this workflow will work, you need to:

1. Generate a WireGuard keypair for the CI peer:
   ```bash
   wg genkey | tee ci-private.key | wg pubkey > ci-public.key
   ```

2. Add the peer to the router's WireGuard config:
   ```ini
   [Peer]
   PublicKey = <contents of ci-public.key>
   AllowedIPs = 10.1.2.200/32
   ```

3. Add GitHub secrets (listed above)

4. Ensure `providers.tfvars` in each site directory has the non-secret values committed (it already does for hawkfield)

### Files Changed

- **New:** `.github/workflows/terraform-plan.yaml` — the PR plan workflow
- **Updated:** `.github/workflows/terraform.yaml` — fix working directory paths (hawkfield instead of kubernetes), keep as the apply-on-merge workflow
