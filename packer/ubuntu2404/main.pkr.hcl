packer {
  required_plugins {
    proxmox = {
      version = "1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu2404" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  iso_file     = var.iso_file
  iso_checksum = var.iso_checksum
  unmount_iso  = var.unmount_iso

  node    = "pve"
  sockets = 1
  cores   = 2
  memory  = 4096

  cpu_type = "host"
  os       = "l26"
  numa     = true

  vga {
    type = "virtio"
    memory = 32
  }

  network_adapters {
    model  = "e1000"
    bridge = "vmbr0"
  }

  disks {
    disk_size    = "10G"
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  additional_iso_files {
    iso_storage_pool = "local"
    cd_files = ["../cloud-init/meta-data", "../cloud-init/user-data"]
    cd_label         = "cidata"
    unmount          = true
  }

  boot_wait         = "1s"
  boot_key_interval = "3s"
  boot_command = [
    "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
    "e<wait>",
    "<down><down><down><end><left><left><left><left><wait5>",
    "autoinstall",
    "<wait>",
    "<f10>",
  ]

  ssh_host     = "127.0.0.1"
  ssh_port     = 2223
  ssh_timeout  = "1h"
  ssh_username = "ansible"
  ssh_password = var.ssh_password

  serials = ["socket"]
}

build {
  sources = ["source.proxmox-iso.ubuntu2404"]

  provisioner "shell" {
    script = "scripts/non-interactive-front-end.sh"
  }

  provisioner "shell" {
    script = "scripts/update.sh"
  }
}