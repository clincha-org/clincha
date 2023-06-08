variable "networks" {
  default = [
    {
      bridge    = "vmbr0"
      firewall  = false
      link_down = false
      model     = "virtio"
    }
  ]
}