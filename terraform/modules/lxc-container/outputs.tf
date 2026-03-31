output "container_id" {
  description = "The Proxmox container ID"
  value       = proxmox_lxc.container.vmid
}

output "hostname" {
  description = "The container hostname"
  value       = proxmox_lxc.container.hostname
}

output "ip_address" {
  description = "The assigned IP address"
  value       = var.ip_address
}
