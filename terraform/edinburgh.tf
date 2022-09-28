# Kubernetes workers
module "edi-kubeworker-1" {
  name           = "edi-kubeworker-1"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.2.161"
  subnet_mask    = "24"
  gateway        = "192.168.2.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.edinburgh
  }
}
module "edi-kubeworker-2" {
  name           = "edi-kubeworker-2"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.2.162"
  subnet_mask    = "24"
  gateway        = "192.168.2.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.edinburgh
  }
}
module "edi-kubeworker-3" {
  name           = "edi-kubeworker-3"
  source         = "./modules/rhel8"
  tags           = ["base", "kubernetes_worker"]
  ip             = "192.168.2.163"
  subnet_mask    = "24"
  gateway        = "192.168.2.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.edinburgh
  }
}

# Github runners
module "edi-runner-1" {
  name           = "edi-runner-01"
  source         = "./modules/rhel8"
  tags           = ["base", "github_runner"]
  ip             = "192.168.2.164"
  subnet_mask    = "24"
  gateway        = "192.168.2.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.edinburgh
  }
}