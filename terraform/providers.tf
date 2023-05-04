terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
  }
}

provider "proxmox" {
  alias               = "bri-s-01"
  pm_api_url          = "https://192.168.1.11:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.bristol_proxmox_token_secret
  pm_tls_insecure     = true
}

provider "proxmox" {
  alias               = "bri-s-02"
  pm_api_url          = "https://192.168.1.12:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.bristol_proxmox_token_secret
  pm_tls_insecure     = true
}

provider "proxmox" {
  alias               = "bri-s-03"
  pm_api_url          = "https://192.168.1.13:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.bristol_proxmox_token_secret
  pm_tls_insecure     = true
}
