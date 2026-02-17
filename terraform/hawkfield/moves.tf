moved {
  from = module.k8s-hawk-1.proxmox_vm_qemu.k8s-hawk-1
  to   = module.k8s-hawk-1.proxmox_vm_qemu.ubuntu_server
}

moved {
  from = module.k8s-hawk-2.proxmox_vm_qemu.k8s-hawk-1
  to   = module.k8s-hawk-2.proxmox_vm_qemu.ubuntu_server
}

moved {
  from = module.k8s-hawk-3.proxmox_vm_qemu.k8s-hawk-1
  to   = module.k8s-hawk-3.proxmox_vm_qemu.ubuntu_server
}

moved {
  from = module.claw-hawk-1.proxmox_vm_qemu.k8s-hawk-1
  to   = module.claw-hawk-1.proxmox_vm_qemu.ubuntu_server
}
