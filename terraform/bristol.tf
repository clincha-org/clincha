# Kubernetes workers
module "bri-kubeworker-1" {
  name           = "bri-kubeworker-1"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.21"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
}
module "bri-kubeworker-2" {
  name           = "bri-kubeworker-2"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.22"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-02
  }
  target_node = "bri-s-02"
  source_vm   = "bri-s-02-template"
}
module "bri-kubeworker-3" {
  name           = "bri-kubeworker-3"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.23"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
}
module "bri-kubeworker-4" {
  name           = "bri-kubeworker-4"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.24"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-02
  }
  target_node = "bri-s-02"
  source_vm   = "bri-s-02-template"
}

# Github runners
module "bri-runner-1" {
  name           = "bri-runner-01"
  source         = "./modules/rhel8"
  tags           = ["base", "github_runner"]
  ip             = "192.168.1.31"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-01"
  source_vm   = "bri-s-01-template"
}
module "bri-runner-2" {
  name           = "bri-runner-02"
  source         = "./modules/rhel8"
  tags           = ["base", "github_runner"]
  ip             = "192.168.1.32"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-02
  }
  target_node = "bri-s-02"
  source_vm   = "bri-s-02-template"
}