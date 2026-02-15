# Plan: Terraform Plan on Pull Requests

## Goal

Run `terraform plan` automatically on PRs that touch `terraform/**`, posting the plan output as a PR comment so reviewers can see what will change before merging.

## Approach: Tailscale VPN

GitHub-hosted runners join the tailnet via an OAuth client and ephemeral nodes. The `tailscale/github-action` handles setup and teardown — nodes auto-expire after the job completes.

### Network Requirements

Terraform needs to reach two internal services:
- **MinIO** (10.1.2.10:9000) — S3 backend for state
- **Proxmox** (10.1.2.11:8006) — provider API for planning

These sit on the home network (10.1.2.0/24). A **subnet router** on the tailnet must advertise this range so the GitHub runner can reach them without installing Tailscale on each service directly.

### Setup Steps

#### 1. Tailscale ACLs

Add a `tag:ci` tag and allow it to access the internal services:

```json
{
  "tagOwners": {
    "tag:ci": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:ci"],
      "dst": ["10.1.2.10:9000", "10.1.2.11:8006"]
    }
  ]
}
```

#### 2. OAuth Client

Create an OAuth client in the Tailscale admin console:
- Scopes: `devices` (write)
- Tags: `tag:ci`

This gives you `TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET`.

#### 3. Subnet Router

One device on the network needs to advertise `10.1.2.0/24` as a subnet route. This could be:
- The router itself (if it runs Tailscale)
- Any always-on machine on the network (e.g. the NAS, a Pi, or a Proxmox host)

```bash
# On the subnet router device:
tailscale up --advertise-routes=10.1.2.0/24
```

Then approve the route in the Tailscale admin console.

#### 4. GitHub Secrets

| Secret | Purpose |
|--------|---------|
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth client ID |
| `TS_OAUTH_SECRET` | Tailscale OAuth client secret |
| `MINIO_SECRET_KEY` | MinIO secret for S3 backend (already exists) |
| `PM_TF_API_TOKEN_SECRET` | Proxmox API token secret (already exists) |

### Workflow Design

```
PR opened/updated → terraform-plan.yaml triggers
  ├─ Join tailnet (ephemeral node, tag:ci)
  ├─ Verify connectivity to MinIO
  ├─ Install Terraform
  ├─ For each site (hawkfield, london):
  │   ├─ terraform init (with MinIO backend)
  │   ├─ terraform plan (read-only, no apply)
  │   └─ Capture plan output
  ├─ Post combined plan as PR comment
  └─ Node auto-expires (ephemeral)
```

### Key Decisions

1. **Tailscale ephemeral nodes** — auto-clean up, no stale peers
2. **OAuth client + tags** — scoped access, no long-lived auth keys
3. **Subnet router** — no need to install Tailscale on MinIO/Proxmox directly
4. **Plan only, never apply** on PRs
5. **PR comment output** — updates the same comment on re-push (no spam)
