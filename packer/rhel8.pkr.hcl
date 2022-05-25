# Variable Definitions
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "vm_root_password" {
  type      = string
  sensitive = true
}

source "proxmox" "rhel8-template" {

  proxmox_url              = "${var.proxmox_api_url}"
  username                 = "${var.proxmox_api_token_id}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true

  node       = "edi-s-01"
  vm_name    = "rhel8"
  qemu_agent = true

  iso_file = "local:iso/rhel-8.5-x86_64-dvd.iso"

  ssh_username         = "ansible"
  #  ssh_password = "${var.vm_root_password}"
  ssh_private_key_file = "./files/ansible"
  ssh_port             = 22
  ssh_timeout          = "120m"
  disable_kvm          = true

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  boot_command = [
    "<up><wait><tab><wait> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait5>"
  ]
  boot_wait = "3s"

  http_directory    = "http"
  http_bind_address = "192.168.2.12"
  http_port_min     = 8802
  http_port_max     = 8802

  cores  = "8"
  memory = "8192"

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size         = "32G"
    format            = "qcow2"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm-thin"
    type              = "virtio"
  }

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }
}
build {

  name    = "rhel8-template-instance"
  sources = ["source.proxmox.rhel8-template"]

  provisioner "shell" {
    inline = [
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo sync",
    ]
  }
}