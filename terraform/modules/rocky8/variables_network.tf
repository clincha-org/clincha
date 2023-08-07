variable "networks" {
  default = [
    {
      bridge    = "vmbr1"
      firewall  = false
      link_down = false
      model     = "virtio"
    }
  ]
}
