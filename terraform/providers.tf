terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
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
  tenant_id       = "5bdbf6b9-7155-49e5-a3ce-f265fd5ec77e"
  subscription_id = "c6ff6270-64cf-40d6-ae87-e11cca58de61"
  client_id       = "6dbca134-0413-45d7-82ae-9359eba597ad"
}
