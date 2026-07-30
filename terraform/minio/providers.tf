terraform {
  backend "s3" {
    bucket = "terraform"
    endpoints = {
      s3 = "http://10.1.2.10:9000"
    }
    key        = "minio.tfstate"
    access_key = "terraform"

    region                      = "main"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.38.5"
    }
  }
}

provider "minio" {
  minio_server   = var.minio_server
  minio_user     = var.minio_user
  minio_password = var.minio_password
}

variable "minio_server" {
  type = string
}

variable "minio_user" {
  type = string
}

variable "minio_password" {
  type      = string
  sensitive = true
}
