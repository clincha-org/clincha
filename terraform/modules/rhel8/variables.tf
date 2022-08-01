# Required
variable "ansible_id_rsa" {
  default   = ""
  sensitive = true
  type      = string
}

variable "hostname" {
  default = ""
  type    = string
}

variable "name" {
  default = ""
  type    = string
}

variable "port" {
  default = 22
  type    = number
}

variable "target_node" {
  default = "edi-s-01"
  type    = string
}

variable "source_vm" {
  default = "template-rhel8"
  type    = string
}

variable "full_clone" {
  default = true
  type    = bool
}

variable "agent" {
  default = 1
  type    = number
}

variable "sockets" {
  default = 2
  type    = number
}

variable "cores" {
  default = 2
  type    = number
}

variable "memory" {
  default = 4096
  type    = number
}

variable "ip_subnet" {
  # e.g. 192.168.1.2/24
  default = ""
  type    = string
}

variable "tags" {
  default = ["base"]
  type    = list(string)
}