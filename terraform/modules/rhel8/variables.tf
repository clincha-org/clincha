variable "ansible_id_rsa" {
  sensitive = true
  type      = string
}

variable "name" {
  type = string
}

variable "desc" {
  type    = string
  default = "Built by Terraform"
}

variable "port" {
  default = 22
  type    = number
}

variable "target_node" {
  type = string
}

variable "source_vm" {
  type = string
  default = "rocky-template"
}

variable "full_clone" {
  default = false
  type    = bool
}

variable "agent" {
  default = 1
  type    = number
}

variable "sockets" {
  default = 1
  type    = number
}

variable "cores" {
  default = 4
  type    = number
}

variable "memory" {
  default = 8192
  type    = number
}

variable "tags" {
  default = ["base"]
  type    = list(string)
}

variable "ip" {
  type = string
}

variable "subnet_mask" {
  default = "24"
  type    = string
}

variable "gateway" {
  type = string
}

variable "connection_user" {
  default = "ansible"
  type    = string
}

variable "onboot" {
  default = true
  type    = bool
}

variable "numa" {
  default = true
  type    = bool
}

variable "hotplug" {
  default = "network,disk,cpu,memory,usb"
  type    = string
}

variable "scsihw" {
  default = "virtio-scsi-pci"
  type    = string
}

variable "os_type" {
  default = "cloud-init"
  type    = string
}
