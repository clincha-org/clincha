module "k8s-lon-1" {
  source         = "../modules/ubuntu-server"
  name           = "k8s-lon-1"
  target_node    = "lon01"
  vmid           = 111
  ip_address     = "10.2.2.101"
  gateway        = "10.2.2.1"
  cores          = 4
  memory         = 8192
  boot_disk_size    = "50"
  data_disk_storage = "local-lvm"
  network_bridge    = "vmbr0"
  tags           = "base,kubernetes_master,kubernetes_worker,watchdog"
}

module "dns-lon-1" {
  source          = "../modules/lxc-container"
  hostname        = "dns-lon-1"
  target_node     = "lon01"
  vmid            = 131
  ip_address      = "10.2.2.131"
  gateway         = "10.2.2.1"
  network_bridge  = "vmbr0"
  ssh_public_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0PsOw/7B9Qr16/iKa2h3j5Nr0jZtrj+JI8qKgYSWep ansible"
  tags            = "adguard"
}
