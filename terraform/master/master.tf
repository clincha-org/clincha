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
    bridge = var.network_bridge
    model  = "virtio"
    mtu    = 1 # Inherit from bridge
  }

  os_type   = "ubuntu"
  ipconfig0 = "ip=${var.ip_address}/24,gw=${var.gateway}"
  onboot    = true

  tags = "base,kubernetes_master,kubernetes_worker"

  scsihw = "virtio-scsi-single"
  disks {
    ide {
      ide3 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size     = var.boot_disk_size
          storage  = "local-lvm"
          iothread = "true"
        }
      }
      virtio1 {
        disk {
          size     = var.data_disk_size
          storage  = "fast"
          iothread = "true"
        }
      }
    }
  }
}