# Github runners
module "edi-runner-1" {
  providers = {
    proxmox = proxmox
  }
  name      = "edi-runner-01"
  source    = "./modules/rhel8"
  tags      = "base,github_runner"
  ip_subnet = "192.168.2.164/24"
  port      = "16004"
}

# Kubernetes workers
module "edi-kubeworker-3" {
  providers = {
    proxmox = proxmox
  }
  name      = "edi-kubeworker-3"
  source    = "./modules/rhel8"
  tags      = "base,kubernetes_worker"
  ip_subnet = "192.168.2.163/24"
  port      = "16003"
}
module "edi-kubeworker-2" {
  providers = {
    proxmox = proxmox
  }
  name      = "edi-kubeworker-2"
  source    = "./modules/rhel8"
  tags      = "base,kubernetes_worker"
  ip_subnet = "192.168.2.162/24"
  port      = "16002"
}
module "edi-kubeworker-1" {
  providers = {
    proxmox = proxmox
  }
  name      = "edi-kubeworker-1"
  source    = "./modules/rhel8"
  tags      = "base,kubernetes_worker"
  ip_subnet = "192.168.2.161/24"
  port      = "16001"
}