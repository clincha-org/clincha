variable "network_brige" {
  default = "vmbr0"
  type    = string
}
variable "network_firewall" {
  default = false
  type    = bool
}
variable "network_link_down" {
  default = false
  type    = bool
}
variable "network_model" {
  default = "virtio"
  type    = string
}