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

variable "tags" {
  default = ["base"]
  type    = list(string)
}

variable "ip" {
  default = ""
  type = string
}

variable "subnet_mask" {
  default = "24"
  type = string
}

variable "gateway" {
  default = ""
  type = string
}

variable "connection_user" {
  default = "ansible"
  type = string
}