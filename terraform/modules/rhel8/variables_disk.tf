variable "disk_size" {
  default = "32G"
  type    = string
}
variable "disk_storage" {
  default = "local-lvm"
  type    = string
}
variable "disk_type" {
  default = "scsi"
  type    = string
}
