variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "ssh_username" {
  type    = string
  default = "ansible"
}

variable "ansible_ssh_password" {
  type      = string
  sensitive = true
}

variable "http_bind_address" {
  type    = string
  default = "0.0.0.0"
}

variable "http_directory" {
  type    = string
  default = "http"
}

variable "node" {
  type = string
}

variable "iso" {
  type = string
}