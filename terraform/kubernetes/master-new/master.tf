resource "proxmox_vm_qemu" "k8s-master-1" {
  name        = var.name
  target_node = var.target_node
  vmid        = var.vmid

  clone = "ubuntu2404"

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = "host"
  }

  memory = var.memory
  agent  = var.agent

  network {
    id     = 0
    bridge = "vmbr1"
    model  = "virtio"
    mtu    = 1 # Inherit from bridge
  }

  os_type   = "ubuntu"
  ipconfig0 = "ip=${var.ip_address}/24,gw=10.1.2.1"
  onboot    = true

  tags = "base,kubernetes_master,kubernetes_worker"

  scsihw = "virtio-scsi-single"

  disk {
    type    = "cloudinit"
    storage = "local-lvm"
    slot    = "ide2"
  }

  disk {
    size     = "64G"
    storage  = "local-lvm"
    type     = "disk"
    iothread = true
    slot     = "virtio0"
  }

  disk {
    size     = "100G"
    storage  = "local-lvm"
    type     = "disk"
    iothread = true
    slot     = "virtio1"
  }

}