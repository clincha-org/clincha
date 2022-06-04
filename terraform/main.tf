terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

variable "ansible_id_rsa" {
  default   = ""
  sensitive = true
}

variable "proxmox_token_secret" {
  default   = ""
  sensitive = true
}

provider "proxmox" {
  pm_api_url          = "https://88.98.250.18:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = true
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
  full_clone  = true
  agent       = 1

  sockets = 2
  cores   = 2
  memory  = 4096

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.2.16${each.value}/24,gw=192.168.2.1"

  tags = "base,github-runner"

  provisioner "remote-exec" {
    connection {
      host        = "clincha.co.uk"
      type        = "ssh"
      user        = "ansible"
      private_key = var.ansible_id_rsa
      # Horrible solution. I need a manual firewall change for every new host
      port        = "1600${each.value}"
    }

    inline = ["sudo hostnamectl set-hostname ${each.key}"]
  }

}