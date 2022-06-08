terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://clincha.co.uk:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = true
}

# Github runners
module "edi-runner-1" {
  name      = "edi-runner-01"
  source    = "modules/rhel8"
  tags      = "base,github_runner"
  ip_subnet = "192.168.2.164/24"
  port      = "16004"
}

# Kubernetes workers
module "edi-kubeworker-3" {
  name      = "edi-kubeworker-3"
  source    = "modules/rhel8"
  tags      = "base,kubernetes_worker"
  ip_subnet = "192.168.2.163/24"
  port      = "16003"
}
module "edi-kubeworker-2" {
  name      = "edi-kubeworker-2"
  source    = "modules/rhel8"
  tags      = "base,kubernetes_worker"
  ip_subnet = "192.168.2.162/24"
  port      = "16002"
}
module "edi-kubeworker-1" {
  name      = "edi-kubeworker-1"
  source    = "modules/rhel8"
  tags      = "base,kubernetes_worker"
  ip_subnet = "192.168.2.161/24"
  port      = "16001"
}