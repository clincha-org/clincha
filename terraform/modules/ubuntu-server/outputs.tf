output "vm_id" {
  description = "The Proxmox VM ID"
  value       = proxmox_vm_qemu.this.vmid
}

output "name" {
  description = "The VM name"
  value       = proxmox_vm_qemu.this.name
}

output "ip_address" {
  description = "The assigned IP address"
  value       = var.ip_address
}
