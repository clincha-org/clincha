resource "proxmox_vm_qemu" "rhel8-worker" {
  provider = "Telmate/proxmox"

  name        = var.name
  target_node = var.target_node
  clone       = var.source_vm
  full_clone  = var.full_clone
  agent       = var.agent

  sockets = var.sockets
  cores   = var.cores
  memory  = var.memory

  os_type   = "cloud-init"
  ipconfig0 = "ip=${var.ip_subnet},gw=192.168.2.1"

  tags = var.tags

  provisioner "remote-exec" {
    connection {
      host        = "clincha.co.uk"
      type        = "ssh"
      user        = "ansible"
      private_key = var.ansible_id_rsa
      port        = var.port
    }

    inline = ["sudo hostnamectl set-hostname ${var.name}"]
  }

}