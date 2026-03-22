# Proxmox connection details
variable proxmox_url {
  type    = string
  default = "https://localhost:8006/api2/json"
}
variable proxmox_username {
  type    = string
  default = "packer@pam!packer"
}
variable proxmox_token {
  type    = string
  default = ""
}
variable proxmox_insecure_skip_tls_verify {
  type    = bool
  default = true
}

# ISO details
variable iso_file {
  type    = string
  default = "local:iso/ubuntu.iso"
}
variable iso_checksum {
  type    = string
  default = "none"
}
variable unmount_iso {
  type    = bool
  default = true
}

# SSH details
variable ssh_host {
  type    = string
  default = "127.0.0.1"
}
variable ssh_port {
  type    = number
  default = 22
}
variable ssh_username {
  type    = string
  default = "ansible"
}
variable ssh_password {
  type    = string
  default = "vagrant"
}
variable ssh_timeout {
  type    = string
  default = "20m"
}

# Boot details
variable boot_wait {
  type    = string
  default = "5s"
}
variable boot_command {
  type = list(string)
  default = [
    "<spacebar><wait>",
    "e<wait>",
    "<down><down><down><end><left><left><left><left><wait>",
    "autoinstall",
    "<wait>",
    "<f10>",
  ]
}

variable node {
  type    = string
  default = "pve"
}

variable vm_id {
  type = string
  default = 100
}

variable disk_size {
  type    = string
  default = "50G"
}

variable storage_pool {
  type    = string
  default = "local-lvm"
}