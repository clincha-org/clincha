variable "proxmox_api_url" {
  type        = string
  default     = "https://192.168.1.11:8006/api2/json"
  description = "The URL to reach the Proxmox node's API"
}
variable "proxmox_api_token_id" {
  type        = string
  default     = "packer@pam!packer"
  description = "The identifier of the token in the format of '<USERNAME>@<USER_TYPE>!<TOKEN_NAMEs>'"
}
variable "proxmox_api_token_secret" {
  type        = string
  sensitive   = true
  default     = "secret"
  description = "The Proxmox API token"
}
variable "insecure_skip_tls_verify" {
  type        = string
  default     = true
  description = "Skip certificate validation"
}
variable "node" {
  type        = string
  default     = "bri-s-01"
  description = "The compute node to deploy the VM template onto"
}
variable "vm_name" {
  type        = string
  default     = "rocky8"
  description = "The name of the VM that will become the template"
}
variable "vm_id" {
  type        = number
  default     = 1000
  description = "The ID of the template"
}
variable "qemu_agent" {
  type        = bool
  default     = true
  description = "Uses the QEMU agent to query the VM properties"
}
variable "os" {
  type        = string
  default     = "l26"
  description = "The OS type of the VM"
}
variable "iso" {
  type        = string
  default     = "local:iso/Rocky-8.8-x86_64-dvd1.iso"
  description = "Location of the ISO to boot from"
}
variable "ssh_username" {
  type        = string
  default     = "ansible"
  description = "The SSH username to use when connecting to the VM to provision"
}
variable "ansible_ssh_password" {
  type        = string
  default     = "secret"
  description = "The SSH password to use when connecting to the VM to provision"
  sensitive   = true
}
variable "ssh_port" {
  type        = number
  default     = 22
  description = "The SSH port to use when connecting to the VM to provision"
}
variable "ssh_timeout" {
  type        = string
  default     = "45m"
  description = "The time to wait for an SSH connection to become available before failing the build"
}
variable "cloud_init" {
  type        = bool
  default     = true
  description = "Flag to check if cloud-init is installed on the VM"
}
variable "cloud_init_storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "Name of the Proxmox storage pool to store the cloud-init CDROM on"
}
variable "boot_command" {
  type    = list(string)
  default = [
    "<up><wait><tab><wait> text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky8.ks<enter><wait5>"
  ]
  description = "Command to send to the template as it starts up"
}
variable "boot_wait" {
  type        = string
  default     = "2s"
  description = "Time to wait before typing the boot command"
}
variable "on_boot" {
  type        = bool
  default     = true
  description = "Should this VM automatically start if the Proxmox server is restarted"
}
variable "http_directory" {
  type        = string
  default     = "http"
  description = "Directory to serve on the webserver Packer creates. In other words - where is the Kickstarter file located?"
}
variable "http_bind_address" {
  type        = string
  default     = "0.0.0.0"
  description = "IP address to bind the webserver to"
}
variable "cpu_type" {
  type        = string
  default     = "host"
  description = "The CPU type to emulate"
}
variable "cores" {
  type        = number
  default     = 4
  description = "Number of CPU cores to build the machine with"
}
variable "memory" {
  type        = number
  default     = 8192
  description = "Amount of RAM to build the machine with"
}

variable "scsi_controller" {
  type        = string
  default     = "virtio-scsi-single"
  description = "The SCSI controller model to emulate"
}
variable "disk_size" {
  type        = number
  default     = 32
  description = "The size of the boot disk"
}
variable "disk_storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "The storage pool to deploy the disk onto"
}
variable "disk_storage_pool_type" {
  type        = string
  default     = "rbd"
  description = "The type of the pool defined by disk_storage_pool"
}
variable "disk_type" {
  type        = string
  default     = "virtio"
  description = "The type of disk to be created"
}
variable "disk_format" {
  type        = string
  default     = "raw"
  description = "The format of the disk to be created"
}
variable "disk_cache_mode" {
  type        = string
  default     = "none"
  description = "How to cache operations to the disk. Can be none, writethrough, writeback, unsafe or directsync."
}

variable "network_model" {
  type        = string
  default     = "virtio"
  description = "Model of the virtual network adapter"
}
variable "network_bridge" {
  type        = string
  default     = "vmbr1"
  description = "The hypervisor network bride to attach the VNIC to"
}
variable "build_name" {
  type        = string
  default     = "rocky8"
  description = "The name for the build"
}
variable "unmount_iso" {
  type        = bool
  default     = true
  description = "Should the ISO be unmounted once the build has finished"
}
