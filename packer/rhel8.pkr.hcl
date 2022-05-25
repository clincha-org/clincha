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
  vm_name    = "template-rhel8"
  qemu_agent = true

  iso_file = "local:iso/rhel-8.5-x86_64-dvd.iso"

  ssh_username = "ansible"
  ssh_password = "${var.vm_root_password}"
  ssh_port     = 22
  ssh_timeout  = "10m"

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
      "mkdir -m0700 -p /home/ansible/.ssh/",
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQChH7t7zLGeRejt1igmRK6t3KgdmKj2y+D6PLrGq93gPh3upfVbNEHlKJwi8c06GXKwWADtctTADsO/Ui6Kl0UHCSVufspnq0XjKHNpjRVwGRQesVJ+pKG8py/cYCHuu1QEDqUkjvhv3349qZB/B+kwHfu6Dk7QJ54x4omCB5pmjSWYiWhHpPKZseGO99cJGdbxkW7GVJHSFjxVhJ3c/hjWTLd1BaE39dZIDc9RRUW9iAJBUfgRfYwHtMZRhW8JXpJHhSVEbZbmyY3jACB9NO21ZOUgEOwlgH8zlI0xT9keg+IV/Nbutz7liLuFlQudv8t5icXhNzgtq8ie20G7H5ahTdY2dShwnSzEi0ulisukR5ceJUgPH0KjqxzYeGtE3E/75amEXjiX9UP0FBuORl50RKDaHzXck0BLZm/jZRBgHFcKi7xdFcwhEuxyM1pkj3DcBPVr/KmcGupgZWs/BY+XsvOpqoXBFCgy/Qtcz+Sr/yv5Nm11N2fRvkJSEEKIiZP0Qy/wLkgto12XleWQu1O4CZ0iAcWWqvvSb81Pu9AbBDgtdakByU41XcsjIc/zZG9kG54JaCy1X+62t0tEeZlxnL/gK3IT15x8pYUr+sCtn19lj6z9wTi4GhTiW5MSaqgpGaoUBnDpZPQ47K6/M1KF+N2hMwUd6qLg+O7nN2W8ew== angus.clinch@gmail.com' > /home/ansible/.ssh/authorized_keys",
      "chmod 0600 /home/ansible/.ssh/authorized_keys",
      "chown -R ansible:ansible /home/ansible/",
      "sudo service sshd restart",
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