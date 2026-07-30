terraform {
  backend "s3" {
    bucket = "terraform"
    endpoints = {
      s3 = "http://10.1.2.10:30293"
    }
    key        = "rustfs.tfstate"
    access_key = "terraform"

    region                      = "main"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }
  required_providers {
    rustfs = {
      source  = "weinmann-emt/rustfs"
      version = "0.0.8"
    }
  }
}

provider "rustfs" {
  endpoint      = var.rustfs_endpoint
  access_key    = var.rustfs_admin
  access_secret = var.rustfs_password
  ssl           = false
}

variable "rustfs_endpoint" {
  type = string
}

# Named _admin rather than _user to avoid shadowing the rustfs_user resource type.
variable "rustfs_admin" {
  type = string
}

variable "rustfs_password" {
  type      = string
  sensitive = true
}
