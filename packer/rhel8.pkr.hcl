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
  vm_id      = "500"
  vm_name    = "rhel8"
  qemu_agent = true

  iso_file    = "local:iso/rhel-8.5-x86_64-dvd.iso"
  unmount_iso = true

  ssh_username = "root"
  ssh_password = "${var.vm_root_password}"
  ssh_timeout  = "60m"
  disable_kvm  = true

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  boot_command = [
    "<up><wait><tab><wait> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait5>"
  ]
  boot_wait = "1s"

  http_directory    = "http"
  http_bind_address = "192.168.1.15"
  http_port_min     = 8802
  http_port_max     = 8802

  cores  = "8"
  memory = "12288"

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

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}