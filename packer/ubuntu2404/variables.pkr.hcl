# Proxmox connection details
variable proxmox_url {
  type    = string
  default = "https://localhost:8006/api2/json"
}
variable proxmox_username {
  type    = string
  default = "root@pam"
}
variable proxmox_password {
  type    = string
  default = "vagrant"
}
variable proxmox_insecure_skip_tls_verify {
  type    = bool
  default = true
}

# ISO details
variable iso_file {
  type    = string
  default = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
}
variable iso_checksum {
  type    = string
  default = "sha256:e240e4b801f7bb68c20d1356b60968ad0c33a41d00d828e74ceb3364a0317be9"
}
variable unmount_iso {
  type    = bool
  default = true
}
