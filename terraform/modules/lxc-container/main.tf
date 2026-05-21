terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

resource "proxmox_lxc" "container" {
  hostname    = var.hostname
  target_node = var.target_node
  vmid        = var.vmid

  ostemplate = var.ostemplate

  cores  = var.cores
  memory = var.memory

  unprivileged = true
  start        = true
  onboot       = true

  features {
    nesting = true
  }

  password = var.password

  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = "${var.ip_address}/24"
    gw     = var.gateway
  }

  nameserver = var.nameserver

  ssh_public_keys = var.ssh_public_keys

  tags = var.tags
}
