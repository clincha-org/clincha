resource "proxmox_vm_qemu" "rhel8-worker" {
  name        = var.name
  target_node = var.target_node
  clone       = var.source_vm
  full_clone  = var.full_clone
  agent       = var.agent

  sockets = var.sockets
  cores   = var.cores
  memory  = var.memory

  os_type   = "cloud-init"
  ipconfig0 = "ip=${ var.ip }/${ var.subnet_mask },gw=${ var.gateway }"

  tags = join(",", var.tags)

  provisioner "remote-exec" {
    connection {
      host        = var.ip
      type        = "ssh"
      user        = var.connection_user
      private_key = var.ansible_id_rsa
      port        = var.port
    }

    inline = ["sudo hostnamectl set-hostname ${ var.name }"]
  }

}