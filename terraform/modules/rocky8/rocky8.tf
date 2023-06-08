resource "proxmox_vm_qemu" "rocky8" {
  name        = var.name
  desc        = var.desc
  target_node = var.target_node
  clone       = var.source_vm
  full_clone  = var.full_clone
  agent       = var.agent
  onboot      = var.onboot
  numa        = var.numa
  hotplug     = var.hotplug
  scsihw      = var.scsihw

  sockets = var.sockets
  cores   = var.cores
  memory  = var.memory

  os_type    = var.os_type
  ipconfig0  = "ip=${ var.ip }/${ var.subnet_mask },gw=${ var.gateway }"

  tags = join(",", var.tags)

  dynamic "disk" {
    for_each = var.disks
    content {
      size    = disk.value.size
      storage = disk.value.storage
      type    = disk.value.type
    }
  }

  dynamic "network" {
    for_each = var.networks
    content {
      bridge    = network.value.bridge
      firewall  = network.value.firewall
      link_down = network.value.link_down
      model     = network.value.model
    }
  }

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
