terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://192.168.2.174:8006/api2/json"
  pm_api_token_id = "terraform@pam!terraform"
}

resource "proxmox_vm_qemu" "rhel8-worker" {
  for_each = {
    edi-kubeworker-1 = "1"
    edi-kubeworker-2 = "2"
    edi-kubeworker-3 = "3"
    edi-runner-1     = "4"
  }

  name        = each.key
  target_node = "edi-s-01"
  clone       = "template-rhel8"
  full_clone  = false
  agent       = 1

  sockets = 2
  cores   = 2
  memory  = 4096

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.2.16${each.value}/24,gw=192.168.2.1"

  tags = "base,github-runner"

  provisioner "remote-exec" {
    connection {
      host        = "192.168.2.16${each.value}"
      type        = "ssh"
      user        = "ansible"
      private_key = file("../id_rsa")
      port        = 22
    }

    inline = ["sudo hostnamectl set-hostname ${each.key}"]
  }

}