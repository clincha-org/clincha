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

  node    = var.node
  sockets = 1
  cores   = 2
  memory = 4096

  # cpu_type = "host"
  os   = "l26"
  numa = false

  network_adapters {
    model  = "e1000"
    bridge = "vmbr0"
  }

  disks {
    disk_size    = "10G"
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  cloud_init = true
  cloud_init_storage_pool = "local-lvm"

  additional_iso_files {
    iso_storage_pool = "local"
    cd_files = ["../cloud-init/meta-data", "../cloud-init/user-data"]
    cd_label         = "cidata"
    unmount          = true
  }

  boot_wait = var.boot_wait
  boot_command = var.boot_command

  # ssh_host     = var.ssh_host
  ssh_port     = var.ssh_port
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = var.ssh_timeout
}

build {
  sources = ["source.proxmox-iso.ubuntu2404"]

  provisioner "shell" {
    script = "../scripts/non-interactive-front-end.sh"
  }

  provisioner "shell" {
    script = "../scripts/update.sh"
  }
}