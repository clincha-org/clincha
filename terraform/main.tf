terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.2.174:8006/api2/json"
}

resource "proxmox_vm_qemu" "rhel8-instance" {
  name        = "rhel8-instance"
  target_node = "edi-s-01"
  clone       = "rhel8"
  agent       = 1

  sockets = 2
  cores   = 2

}