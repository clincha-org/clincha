output "vm_id" {
  description = "The Proxmox VM ID"
  value       = proxmox_vm_qemu.ubuntu_server.vmid
}

output "name" {
  description = "The VM name"
  value       = proxmox_vm_qemu.ubuntu_server.name
}

output "ip_address" {
  description = "The assigned IP address"
  value       = var.ip_address
}
