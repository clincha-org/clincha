module "k8s-master-1" {
  source      = "./master"
  name        = "k8s-master-1"
  target_node = "hawk01"
  vmid        = 111
  ip_address  = "10.1.2.101"
}

module "k8s-master-2" {
  source      = "./master"
  name        = "k8s-master-2"
  target_node = "hawk02"
  vmid        = 112
  ip_address  = "10.1.2.102"
}

module "k8s-master-3" {
  source      = "./master"
  name        = "k8s-master-3"
  target_node = "hawk03"
  vmid        = 113
  ip_address  = "10.1.2.103"
}
