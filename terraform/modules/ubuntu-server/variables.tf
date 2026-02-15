# NODE
variable "name" {
  description = "The name of the node"
  type        = string
}
variable "target_node" {
  description = "The physical server to deploy to"
  type        = string
}
variable "vmid" {
  description = "The ID of the virtual machine"
  type        = string
}

# CLONE
variable "clone" {
  description = "The name of the virtual machine to clone"
  default     = "ubuntu2404"
  type        = string
}

# CPU / MEMORY
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
  description = "Run the Proxmox agent on the guest"
  default     = 1
  type        = number
}

# NET
variable "ip_address" {
  description = "The IP address of the node"
  type        = string
}
variable "gateway" {
  description = "The gateway for the node"
  default     = "10.1.2.1"
  type        = string
}
variable "network_bridge" {
  description = "The network bridge to attach to"
  default     = "vmbr1"
  type        = string
}

# DISKS
variable "boot_disk_size" {
  description = "The size of the boot disk"
  default     = "50G"
  type        = string
}
variable "data_boot_storage" {
  description = "Storage pool for the boot disk"
  default     = "local-lvm"
  type        = string
}
variable "data_disk_size" {
  description = "The size of the data disk"
  default     = "100G"
  type        = string
}
variable "data_disk_storage" {
  description = "The storage pool for the data disk"
  default     = "fast"
  type        = string
}

# TAGS
variable "tags" {
  description = "Comma-separated list of tags to apply to the VM"
  default     = "base"
  type        = string
}
