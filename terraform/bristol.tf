# Kubernetes workers
module "bri-master-1" {
  name           = "bri-master-1"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker", "kubernetes_master"]
  ip             = "192.168.1.20"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
  desc        = "Kubernetes master node in Bristol (region 1)"
}
module "bri-kubeworker-1" {
  name           = "bri-kubeworker-1"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.21"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
  desc        = "Kubernetes worker node in Bristol (region 1)"
  disks = [
    {
      size    = "32G"
      storage = "local-lvm"
      type    = "scsi"
    },
    {
      size    = "16G"
      storage = "bri-s-01-cache"
      type    = "scsi"
    }
  ]
}
module "bri-kubeworker-2" {
  name           = "bri-kubeworker-2"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.22"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-02
  }
  target_node = "bri-s-02"
  source_vm   = "bri-s-02-template"
  desc        = "Kubernetes worker node in Bristol (region 2)"
  disks = [
    {
      size    = "32G"
      storage = "local-lvm"
      type    = "scsi"
    },
    {
      size    = "16G"
      storage = "bri-s-02-cache"
      type    = "scsi"
    }
  ]
}
module "bri-kubeworker-3" {
  name           = "bri-kubeworker-3"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.23"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
  desc        = "Kubernetes worker node in Bristol (region 1)"
  disks = [
    {
      size    = "32G"
      storage = "local-lvm"
      type    = "scsi"
    },
    {
      size    = "16G"
      storage = "bri-s-01-cache"
      type    = "scsi"
    }
  ]
}
module "bri-kubeworker-4" {
  name           = "bri-kubeworker-4"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-02
  }
  target_node = "bri-s-02"
  source_vm   = "bri-s-02-template"
  desc        = "Kubernetes worker node in Bristol (region 2)"
  disks = [
    {
      size    = "32G"
      storage = "local-lvm"
      type    = "scsi"
    },
    {
      size    = "16G"
      storage = "bri-s-02-cache"
      type    = "scsi"
    }
  ]
}

# Github runners
module "bri-runner-1" {
  name           = "bri-runner-01"
  source         = "./modules/rhel8"
  tags           = ["base", "github_runner"]
  ip             = "192.168.1.31"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
  desc        = "GitHub runner node in Bristol (region 1)"
}
module "bri-runner-2" {
  name           = "bri-runner-02"
  source         = "./modules/rhel8"
  tags           = ["base", "github_runner"]
  ip             = "192.168.1.32"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-02
  }
  target_node = "bri-s-02"
  source_vm   = "bri-s-02-template"
  desc        = "GitHub runner node in Bristol (region 2)"
}

# NFS Servers
module "bri-nfs-1" {
  name           = "bri-nfs-1"
  source         = "./modules/rhel8"
  tags           = ["base", "nfs_server"]
  ip             = "192.168.1.41"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
  desc        = "NFS server in Bristol (region 1)"

  disks = [
    {
      size    = "32G"
      storage = "local-lvm"
      type    = "scsi"
    },
    {
      size    = "5000G"
      storage = "bri-s-01-data"
      type    = "scsi"
    }
  ]
}
module "bri-nfs-2" {
  name           = "bri-nfs-2"
  source         = "./modules/rhel8"
  tags           = ["base", "nfs_server"]
  ip             = "192.168.1.42"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-02
  }
  target_node = "bri-s-02"
  source_vm   = "bri-s-02-template"
  desc        = "NFS server in  Bristol (region 2)"

  disks = [
    {
      size    = "32G"
      storage = "local-lvm"
      type    = "scsi"
    },
    {
      size    = "5000G"
      storage = "bri-s-02-data"
      type    = "scsi"
    }
  ]
}