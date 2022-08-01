variable "ansible_id_rsa" {
  default   = ""
  sensitive = true
  type = string
}

variable "proxmox_token_secret" {
  default   = ""
  sensitive = true
  type = string
}