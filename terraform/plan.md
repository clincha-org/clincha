# Terraform Refactor Plan: Ubuntu Server Module

## Problem

The `master/` and `claw/` directories contain near-identical Terraform code for provisioning Proxmox VMs. The only meaningful difference is that `claw/` adds a `tags` variable. This duplication makes maintenance harder — any change to the VM resource definition needs to be made in two places.

## Current Structure

```
terraform/
├── backend.conf.sample
├── README.md
├── master/              # Ubuntu VM definition (used by hawkfield + london)
│   ├── master.tf        #   proxmox_vm_qemu resource
│   ├── providers.tf     #   required_providers block
│   └── variables.tf     #   VM config variables
├── claw/                # Copy-paste of master/ with extra `tags` variable
│   ├── master.tf        #   identical resource definition
│   ├── providers.tf     #   identical providers block
│   └── variables.tf     #   same variables + `tags`
├── hawkfield/           # Hawkfield site — uses both master/ and claw/ as modules
│   ├── main.tf
│   ├── providers.tf
│   └── providers.tfvars
└── london/              # London site — uses master/ as module
    ├── main.tf
    ├── providers.tf
    └── providers.tfvars
```

### Key Observations

- `master/master.tf` and `claw/master.tf` are **identical** — same resource, same structure.
- `master/variables.tf` and `claw/variables.tf` are **identical** except `claw/` adds a `tags` variable.
- `master/master.tf` has hardcoded `tags = "base,kubernetes_master,kubernetes_worker"` — this should use the variable instead.
- Both `master/` and `claw/` duplicate the `providers.tf` block (not needed in modules — the caller provides the provider).

## Proposed Structure

```
terraform/
├── backend.conf.sample
├── README.md
├── modules/
│   └── ubuntu-server/       # Single shared module
│       ├── main.tf           #   proxmox_vm_qemu resource (uses var.tags)
│       ├── variables.tf      #   all VM config variables (including tags)
│       └── outputs.tf        #   useful outputs (VM ID, IP, etc.)
├── hawkfield/                # Hawkfield site (unchanged layout)
│   ├── main.tf               #   all VMs use source = "../modules/ubuntu-server"
│   ├── providers.tf
│   └── providers.tfvars
└── london/                   # London site (unchanged layout)
    ├── main.tf               #   all VMs use source = "../modules/ubuntu-server"
    ├── providers.tf
    └── providers.tfvars
```

## Changes Required

### 1. Create `modules/ubuntu-server/`

**`modules/ubuntu-server/main.tf`** — single VM resource using all variables:
- Take the existing resource from `master/master.tf`
- Replace the hardcoded `tags` with `var.tags`
- Remove the `providers.tf` — modules inherit providers from the caller

**`modules/ubuntu-server/variables.tf`** — merge of both variable files:
- All existing variables from `master/variables.tf`
- Add `tags` variable (from `claw/variables.tf`) with a sensible default like `"base"`
- Add `clone` variable usage in the resource (currently defined but hardcoded to `"ubuntu2404"` in the resource)

**`modules/ubuntu-server/outputs.tf`** — expose useful values:
- `vm_id` — the Proxmox VM ID
- `name` — the VM name
- `ip_address` — the assigned IP

### 2. Update `hawkfield/main.tf`

Change all module sources from `"../master"` and `"../claw"` to `"../modules/ubuntu-server"`:

```hcl
module "k8s-hawk-1" {
  source      = "../modules/ubuntu-server"
  name        = "k8s-hawk-1"
  target_node = "hawk01"
  vmid        = 111
  ip_address  = "10.1.2.101"
  tags        = "base,kubernetes_master,kubernetes_worker"
}

# ... same for k8s-hawk-2, k8s-hawk-3

module "claw-hawk-1" {
  source            = "../modules/ubuntu-server"
  name              = "claw-hawk-1"
  target_node       = "hawk02"
  vmid              = 122
  ip_address        = "10.1.2.122"
  cores             = 4
  memory            = 8192
  data_disk_storage = "local-lvm"
  tags              = "base,claw"
}
```

### 3. Update `london/main.tf`

Change module sources from `"../master"` to `"../modules/ubuntu-server"` and add explicit `tags`:

```hcl
module "k8s-lon-1" {
  source         = "../modules/ubuntu-server"
  name           = "k8s-lon-1"
  target_node    = "lon01"
  vmid           = 111
  ip_address     = "10.2.0.101"
  gateway        = "10.2.0.1"
  cores          = 4
  memory         = 4096
  boot_disk_size = "50"
  network_bridge = "vmbr0"
  tags           = "base,kubernetes_master,kubernetes_worker"
}
```

### 4. Delete `master/` and `claw/`

Once the module is in place and both sites reference it, remove the old duplicated directories.

## Migration Notes

- **State migration**: Changing module source paths will require `terraform state mv` commands or `moved` blocks to avoid destroy/recreate cycles. For each VM:
  ```hcl
  # In hawkfield/main.tf (temporary, remove after apply)
  moved {
    from = module.claw-hawk-1.proxmox_vm_qemu.k8s-hawk-1
    to   = module.claw-hawk-1.proxmox_vm_qemu.this
  }
  ```
  (Only needed if the resource name inside the module changes, e.g., from `k8s-hawk-1` to `this`.)

- **Provider version**: `london/` uses `3.0.2-rc04` while `hawkfield/` uses `3.0.2-rc06`. Align both to the same version during this refactor.

- **No functional changes**: The VMs themselves should be unchanged — this is purely a structural refactor.

## Bugs to Fix Along the Way

1. `master/master.tf` has `tags` hardcoded instead of using `var.tags` — the variable exists but isn't wired up
2. `master/master.tf` has `clone = "ubuntu2404"` hardcoded instead of using `var.clone` — same issue
3. The resource name `k8s-hawk-1` inside the module is misleading — rename to `this` or `server` since it's a generic module
