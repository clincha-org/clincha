terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "1.0.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.86.0"
    }
  }
}

provider "proxmox" {
  alias               = "bri-s-01"
  pm_api_url          = "https://clinch-home.com:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform"
  pm_api_token_secret = var.bristol_proxmox_token_secret
  pm_tls_insecure     = true
}

provider "azurerm" {
  features {}
}
