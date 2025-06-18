resource "proxmox_vm_qemu" "k8s-master-1" {
  name        = var.name
  target_node = var.target_node
  vmid        = var.vmid

  clone = "ubuntu2404"

  sockets = var.sockets
  cores   = var.cores
  memory  = var.memory
  agent   = var.agent

  network {
    id     = 0
    bridge = "vmbr1"
    model  = "virtio"
  }

  os_type   = "ubuntu"
  ipconfig0 = "ip=${var.ip_address}/24,gw=10.1.2.1"
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
          size     = "32G"
          storage  = "local-lvm"
          iothread = "true"
        }
      }
      virtio1 {
        disk {
          size     = "64G"
          storage  = "fast"
          iothread = "true"
        }
      }
    }
  }
}