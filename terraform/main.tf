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
  name        = "kube-worker-0"
  target_node = "edi-s-01"
  clone       = "template-rhel8"
  full_clone  = false
  agent       = 1

  sockets = 2
  cores   = 2
  memory  = 4096

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.2.160/24,gw=192.168.2.1"

  provisioner "remote-exec" {
    connection {
      host        = "192.168.2.160"
      type        = "ssh"
      user        = "ansible"
      private_key = file("./ansible")
      port        = 22
    }

    inline = ["sudo hostnamectl set-hostname worker1"]
  }

}