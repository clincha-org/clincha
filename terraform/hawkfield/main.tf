module "k8s-hawk-1" {
  source      = "../master"
  name        = "k8s-hawk-1"
  target_node = "hawk01"
  vmid        = 111
  ip_address  = "10.1.2.101"
}

module "k8s-hawk-2" {
  source            = "../master"
  name              = "k8s-hawk-2"
  target_node       = "hawk02"
  vmid              = 112
  ip_address        = "10.1.2.102"
  data_disk_storage = "local-lvm"
}

module "k8s-hawk-3" {
  source      = "../master"
  name        = "k8s-hawk-3"
  target_node = "hawk03"
  vmid        = 113
  ip_address  = "10.1.2.103"
}

module "claw-hawk-1" {
  source            = "../claw"
  tags              = "base,claw"
  name              = "claw-hawk-1"
  target_node       = "hawk02"
  vmid              = 122
  ip_address        = "10.1.2.122"
  cores             = 4
  memory            = 8192
  data_disk_storage = "local-lvm"
}
