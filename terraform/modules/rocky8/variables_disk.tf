variable "disks" {
  default = [
    {
      type      = "virtio"
      storage   = "ssd"
      size      = "32G"
      format    = "raw"
      cache     = "none"
      backup    = false
      iothread  = 0
      replicate = 0
      ssd       = 1
      discard   = "on"
      media     = "disk"
    }
  ]
}
