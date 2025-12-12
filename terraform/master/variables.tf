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
  default     = 10
  type        = number
}
variable "memory" {
  description = "Memory (Megabytes)"
  default     = 65536
  type        = number
}
variable "agent" {
  description = "Run the Promox agent on the guest"
  default     = 1
  type        = number
}

variable "ip_address" {
  description = "The IP address of the node"
  default     = "10.1.2.101"
  type        = string
}

variable "gateway" {
  description = "The gateway for the node"
  default     = "10.1.2.1"
  type        = string
}

variable "boot_disk_size" {
  description = "The size of the boot disk"
  default     = "50G"
  type        = string
}

variable "data_disk_size" {
  description = "The size of the data disk"
  default     = "100G"
  type        = string
}

variable "network_bridge" {
  description = "The network bridge to attach to"
  default     = "vmbr1"
  type        = string
}
