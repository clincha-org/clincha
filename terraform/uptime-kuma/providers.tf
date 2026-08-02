terraform {
  backend "s3" {
    bucket = "terraform"
    endpoints = {
      s3 = "http://10.1.2.10:30293"
    }
    key        = "uptime-kuma.tfstate"
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

# status.clincha.co.uk only resolves on the LAN, so CI adds a hosts entry
# pointing at the ingress VIP before running. Hitting 10.1.2.205 directly would
# miss the Host header the ingress routes on.
provider "uptimekuma" {
  endpoint = var.endpoint
  username = var.username
  password = var.password
}
