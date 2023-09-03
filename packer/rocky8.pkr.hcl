packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox" "rocky8" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = var.insecure_skip_tls_verify

  node       = var.node
  vm_name    = var.vm_name
  vm_id      = var.vm_id
  qemu_agent = var.qemu_agent

  os          = var.os
  iso_file    = var.iso
  unmount_iso = var.unmount_iso

  ssh_username = var.ssh_username
  ssh_password = var.ansible_ssh_password
  ssh_port     = var.ssh_port
  ssh_timeout  = var.ssh_timeout

  cloud_init              = var.cloud_init
  cloud_init_storage_pool = var.cloud_init_storage_pool

  boot_command = var.boot_command
  boot_wait    = var.boot_wait
  onboot       = var.on_boot

  http_directory    = var.http_directory
  http_bind_address = var.http_bind_address

  cpu_type = var.cpu_type
  cores    = var.cores
  memory   = var.memory

  scsi_controller = var.scsi_controller

  disks {
    disk_size         = var.disk_size
    storage_pool      = var.disk_storage_pool
    storage_pool_type = var.disk_storage_pool_type
    type              = var.disk_type
    format            = var.disk_format
#    ssd               = var.disk_ssd
#    discard           = var.disk_discard
    cache_mode        = var.disk_cache_mode
  }

  network_adapters {
    model  = var.network_model
    bridge = var.network_bridge
  }
}

build {

  name    = var.build_name
  sources = ["source.proxmox.rocky8"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo sync"
    ]
  }

  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg",
      "sudo rm /etc/cloud/cloud-init.disabled"
    ]
  }
}
