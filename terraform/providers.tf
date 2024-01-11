terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.59.0"
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

provider "azurerm" {
  features {}
}
