# Required
variable "ansible_id_rsa" {
  default   = ""
  sensitive = true
  type = string
}

variable "hostname" {
  default = ""
  type = string
}

variable "name" {
  default = ""
  type = string
}

variable "port" {
  default = ""
  type = number
}

# Optional
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
  default = 1
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