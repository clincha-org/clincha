module "bri-fact01" {
  name           = "bri-fact01"
  source         = "./modules/rocky8"
  tags           = ["base"]
  ip             = "10.1.2.85"
  gateway        = "10.1.2.1"
  ansible_id_rsa = var.ansible_id_rsa
  providers      = {
    proxmox = proxmox.bri-s-01
  }
  target_node = "bri-s-03"
  desc        = "Factorio server"
}