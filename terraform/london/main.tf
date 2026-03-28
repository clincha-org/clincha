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
  tags           = "base,kubernetes_master,kubernetes_worker"
}
