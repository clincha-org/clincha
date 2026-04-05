module "claude-hawk-1" {
  source            = "../modules/ubuntu-server"
  name              = "claude-hawk-1"
  target_node       = "hawk02"
  vmid              = 122
  ip_address        = "10.1.2.122"
  cores             = 4
  memory            = 8192
  data_disk_storage = "local-lvm"
  tags              = "base,claude"
}

module "dns-hawk-1" {
  source          = "../modules/lxc-container"
  hostname        = "dns-hawk-1"
  target_node     = "hawk01"
  vmid            = 131
  ip_address      = "10.1.2.131"
  ssh_public_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0PsOw/7B9Qr16/iKa2h3j5Nr0jZtrj+JI8qKgYSWep ansible"
  tags            = "base;pihole"
}
