variable "hostname" {
  description = "The hostname of the container"
  type        = string
}

variable "target_node" {
  description = "The Proxmox node to deploy to"
  type        = string
}

variable "vmid" {
  description = "The ID of the container"
  type        = number
}

variable "ostemplate" {
  description = "The OS template to use"
  default     = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  type        = string
}

variable "cores" {
  description = "CPU cores"
  default     = 2
  type        = number
}

variable "memory" {
  description = "Memory in MB"
  default     = 2048
  type        = number
}

variable "password" {
  description = "Root password for the container"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rootfs_storage" {
  description = "Storage pool for the root filesystem"
  default     = "local-lvm"
  type        = string
}

variable "rootfs_size" {
  description = "Size of the root filesystem"
  default     = "8G"
  type        = string
}

variable "ip_address" {
  description = "The IP address of the container"
  type        = string
}

variable "gateway" {
  description = "The gateway for the container"
  default     = "10.1.2.1"
  type        = string
}

variable "network_bridge" {
  description = "The network bridge to attach to"
  default     = "vmbr1"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver for the container"
  default     = "1.1.1.1"
  type        = string
}

variable "ssh_public_keys" {
  description = "SSH public keys to add to the container"
  default     = ""
  type        = string
}

variable "tags" {
  description = "Semicolon-separated tags for the container"
  default     = "base"
  type        = string
}
