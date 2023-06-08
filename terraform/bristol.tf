# Kubernetes workers
module "bri-master-1" {
  name           = "bri-master-1"
  source         = "modules/rocky8"
  tags           = ["base", "kubernetes_worker", "kubernetes_master"]
  ip             = "192.168.1.20"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  desc        = "Kubernetes master node in Bristol (node 1)"
}

module "bri-kubeworker-1" {
  name           = "bri-kubeworker-1"
  source         = "modules/rocky8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.21"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  desc        = "Kubernetes worker node in Bristol (node 1)"
}

module "bri-kubeworker-2" {
  name           = "bri-kubeworker-2"
  source         = "modules/rocky8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.22"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-02"
  desc        = "Kubernetes worker node in Bristol (node 2)"
}

module "bri-kubeworker-3" {
  name           = "bri-kubeworker-3"
  source         = "modules/rocky8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.23"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-03"
  desc        = "Kubernetes worker node in Bristol (node 3)"
}
