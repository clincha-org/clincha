terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
  }
}

provider "proxmox" {
  alias               = "edinburgh"
  pm_api_url          = "https://192.168.2.174:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.edinburgh_proxmox_token_secret
  pm_tls_insecure     = true
}

provider "proxmox" {
  alias               = "bristol"
  pm_api_url          = "https://192.168.1.11:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.bristol_proxmox_token_secret
  pm_tls_insecure     = true
}