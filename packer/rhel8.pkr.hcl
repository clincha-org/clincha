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

# Resource Definiation for the VM Template
source "proxmox" "rhel8-template" {

  # Proxmox Connection Settings
  proxmox_url = "${var.proxmox_api_url}"
  username    = "${var.proxmox_api_token_id}"
  token       = "${var.proxmox_api_token_secret}"

  # Proxmox Connection Settings
  insecure_skip_tls_verify = true

  node    = "edi-s-01"
  vm_id   = "500"
  vm_name = "rhel8"

  iso_file = "local:iso/rhel-8.5-x86_64-boot.iso"

  ssh_username = "root"
  disable_kvm  = true

  boot_command = [
    "<up><wait><tab><wait> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-manual.cfg<enter><wait5>"
  ]
  boot_wait = "5s"
}
build {

  name    = "rhel8-template-instance"
  sources = ["source.proxmox.rhel8-template"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }
}