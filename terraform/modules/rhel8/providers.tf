terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://clincha.co.uk:8006/api2/json"
}