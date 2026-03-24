terraform {
  backend "s3" {
    # Configured using backend.conf
    # Pass -backend-config=backend.conf to terraform init
    bucket = "terraform"
    endpoints = {
      s3 = "http://10.1.2.10:9000"
    }
    key        = "london.tfstate"
    access_key = "terraform"

    region                      = "main"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}


provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_tls_insecure     = var.pm_tls_insecure
  pm_api_token_secret = var.pm_api_token_secret
}

variable "pm_api_url" {
  type = string
}
variable "pm_api_token_id" {
  type = string
}
variable "pm_tls_insecure" {
  type = bool
}
variable "pm_api_token_secret" {
  type = string
}
