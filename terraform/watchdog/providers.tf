terraform {
  backend "s3" {
    bucket = "terraform"
    endpoints = {
      s3 = "http://10.1.2.10:30293"
    }
    key        = "watchdog.tfstate"
    access_key = "terraform"

    region                      = "main"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }
  required_providers {
    uptimekuma = {
      source  = "breml/uptimekuma"
      version = "0.4.0"
    }
  }
}

# The London instance has no ingress and no DNS name — it is deliberately
# reachable only by IP, so that nothing it monitors is in the path to it.
provider "uptimekuma" {
  endpoint = var.endpoint
  username = var.username
  password = var.password
}
