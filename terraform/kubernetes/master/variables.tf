variable "name" {
  description = "The name of the node"
  default     = "k8s-master-01"
  type        = string
}
variable "target_node" {
  description = "The physical server to deploy to"
  default     = "hawk01"
  type        = string
}
variable "vmid" {
  description = "The ID of the virtual machine"
  default     = "201"
  type        = string
}

variable "clone" {
  description = "The name of the virtual machine to clone"
  default     = "ubuntu2404"
  type        = string
}

variable "sockets" {
  description = "CPU sockets"
  default     = 1
  type        = number
}
variable "cores" {
  description = "CPU cores"
  default     = 8
  type        = number
}
variable "memory" {
  description = "Memory (Megabytes)"
  default     = 32768
  type        = number
}
variable "agent" {
  description = ""
  default     = 1
  type        = number
}

variable "ip_address" {
  description = "The IP address of the node"
  default     = "10.1.2.101"
  type        = string
}