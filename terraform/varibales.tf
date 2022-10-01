variable "ansible_id_rsa" {
  default   = ""
  sensitive = true
  type = string
}

variable "edinburgh_proxmox_token_secret" {
  default   = ""
  sensitive = true
  type = string
}

variable "bristol_proxmox_token_secret" {
  default = ""
  sensitive = true
  type = string
}