variable "ansible_id_rsa" {
  default   = ""
  sensitive = true
}

variable "hostname" {
  default = ""
}

variable "name" {
  default = ""
}

variable "target_node" {
  default = "edi-s-01"
}

variable "source_vm" {
  default = "template-rhel8"
}

variable "full_clone" {
  default = true
}

variable "agent" {
  default = true
}

variable "sockets" {
  default = 2
}

variable "cores" {
  default = 2
}

variable "memory" {
  default = 4096
}

variable "ip_subnet" {
  # e.g. 192.168.1.2/24
  default = ""
}

variable "tags" {
  default = "base"
}

variable "port" {
  default = ""
}