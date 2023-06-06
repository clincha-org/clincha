variable "disks" {
  type    = list(map(string))
  default = [
    {
      size     = "32G"
      storage  = "Hot"
      type     = "scsi"
      discard  = "true"
      iothread = "1"
    }
  ]
}
