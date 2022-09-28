# Kubernetes workers
module "bri-kubeworker-1" {
  name           = "bri-kubeworker-1"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.161"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bristol
  }
}
module "bri-kubeworker-2" {
  name           = "bri-kubeworker-2"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.162"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bristol
  }
}
module "bri-kubeworker-3" {
  name           = "bri-kubeworker-3"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.1.163"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bristol
  }
}

# Github runners
module "bri-runner-1" {
  name           = "bri-runner-01"
  source         = "./modules/rhel8"
  tags           = ["base", "github_runner"]
  ip             = "192.168.1.164"
  subnet_mask    = "24"
  gateway        = "192.168.1.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bristol
  }
}