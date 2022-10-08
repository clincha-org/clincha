source "proxmox" "rhel8-template" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = var.insecure_skip_tls_verify

  node       = var.node
  vm_name    = var.vm_name
  qemu_agent = var.qemu_agent

  iso_file = var.iso

  ssh_username = var.ssh_username
  ssh_password = var.ansible_ssh_password
  ssh_port     = var.ssh_port
  ssh_timeout  = var.ssh_timeout

  cloud_init              = var.cloud_init
  cloud_init_storage_pool = var.cloud_init_storage_pool

  boot_command = var.boot_command
  boot_wait    = var.boot_wait

  http_directory    = var.http_directory
  http_bind_address = var.http_bind_address

  cores  = var.cores
  memory = var.memory

  scsi_controller = var.scsi_controller

  disks {
    disk_size         = var.disk_size
    storage_pool      = var.disk_storage_pool
    storage_pool_type = var.disk_storage_pool_type
    format            = var.disk_format
  }

  network_adapters {
    model  = var.network_model
    bridge = var.network_bridge
  }
}
build {

  name    = var.build_name
  sources = ["source.proxmox.rhel8-template"]

  provisioner "shell" {
    inline = [
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
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}