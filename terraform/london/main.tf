module "k8s-lon-1" {
  source         = "../master"
  name           = "k8s-lon-1"
  target_node    = "lon01"
  vmid           = 111
  ip_address     = "10.2.0.101"
  gateway        = "10.2.0.1"
  cores          = 2
  memory         = 4096
  boot_disk_size = "50"
  network_bridge = "vmbr0"
}

module "k8s-lon-2" {
  source         = "../master"
  name           = "k8s-lon-2"
  target_node    = "lon01"
  vmid           = 112
  ip_address     = "10.2.0.102"
  gateway        = "10.2.0.1"
  cores          = 2
  memory         = 4096
  boot_disk_size = "50"
  network_bridge = "vmbr0"
}

module "k8s-lon-3" {
  source         = "../master"
  name           = "k8s-lon-3"
  target_node    = "lon01"
  vmid           = 113
  ip_address     = "10.2.0.103"
  gateway        = "10.2.0.1"
  cores          = 2
  memory         = 4096
  boot_disk_size = "50"
  network_bridge = "vmbr0"
}
