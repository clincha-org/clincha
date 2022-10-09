variable "ansible_id_rsa" {
  sensitive = true
  type = string
}

variable "edinburgh_proxmox_token_secret" {
  sensitive = true
  type = string
}

variable "bristol_proxmox_token_secret" {
  sensitive = true
  type = string
}