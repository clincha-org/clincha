variable "disks" {
  type    = list(map(string))
  default = [
    {
      size    = "32G"
      storage = "local-lvm"
      type    = "scsi"
    }
  ]
}