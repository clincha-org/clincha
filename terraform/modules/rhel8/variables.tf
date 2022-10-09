variable "ansible_id_rsa" {
  sensitive = true
  type      = string
}

variable "name" {
  type = string
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