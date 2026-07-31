terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

locals {
  queues = var.queues != null ? var.queues : var.cores
}

resource "proxmox_vm_qemu" "ubuntu_server" {
  name        = var.name
  target_node = var.target_node
  vmid        = var.vmid

  clone = var.clone

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = "host"
  }

  memory = var.memory
  agent  = var.agent

  network {
    id     = 0
    bridge = var.network_bridge
    model  = "virtio"
    mtu    = 1 # Inherit from bridge
    queues = local.queues
  }

  os_type            = "ubuntu"
  ipconfig0          = "ip=${var.ip_address}/24,gw=${var.gateway}"
  start_at_node_boot = true
  power_state        = "running"

  tags = var.tags

  scsihw = "virtio-scsi-single"

  # Telmate marks these Optional without Computed, so leaving them unset diffs
  # against what the provider reads back from PVE on every plan.
  startup_shutdown {
    order            = -1
    shutdown_timeout = -1
    startup_delay    = -1
  }

  disk {
    type    = "cloudinit"
    storage = "local-lvm"
    slot    = "ide2"
  }

  disk {
    size     = var.boot_disk_size
    storage  = var.data_boot_storage
    type     = "disk"
    format   = "raw"
    iothread = true
    slot     = "virtio0"
  }

  disk {
    size     = var.data_disk_size
    storage  = var.data_disk_storage
    type     = "disk"
    format   = "raw"
    iothread = true
    slot     = "virtio1"
  }
}
