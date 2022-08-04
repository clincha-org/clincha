source "proxmox" "rhel8-template" {

  proxmox_url              = "${var.proxmox_api_url}"
  username                 = "${var.proxmox_api_token_id}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true

  node       = "edi-s-01"
  vm_name    = "template-rhel8"
  qemu_agent = true

  iso_file = "local:iso/rhel-8.5-x86_64-dvd.iso"

  ssh_username = "ansible"
  ssh_password = "${var.ansible_ssh_password}"
  ssh_port     = 22
  ssh_timeout  = "10m"

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  boot_command = [
    "<up><wait><tab><wait> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait5>"
  ]
  boot_wait = "10s"

  http_directory    = "http"
  http_bind_address = "${var.http_bind_address}"
  http_port_min     = 8802
  http_port_max     = 8802

  cores  = "8"
  memory = "8192"

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size         = "32G"
    format            = "raw"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm-thin"
    type              = "scsi"
  }

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }
}
build {

  name    = "rhel8-template-instance"
  sources = ["source.proxmox.rhel8-template"]

  provisioner "shell" {
    inline = [
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "mkdir -m0700 -p /home/ansible/.ssh/",
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVf+T1KyqUBN5Iaa5BspqvMXvCkoez16n+Dq4LI1LvWbCcfBPvCxJIUQxp86Uyr0Yz8wPrMLyXwbE0LhaeX8RvST/AB/+DleLxMpz1QSaDcIcPqu3GICxhrp6Rrdqm4A6h6dG8TEiAcWylsIxzbaoA9bMQ3X9eeVYYKRcvEDTchPdjodaXtz0mY+YHOHLE2eZ+C/YDVctIh5uJr0yTguIZwFmqVVZWAqsEZsa+Xk4Fe4PyunDiL0cKB26NuIAnHWG54uIPFlREgwCQfJWQdziFL60mo++8RxqwVODFsNOQdGEWSTnKRK0alWHAq5Go7rdu5nPTPlSV3hAYUApmv7uO0wXvQhMWvqXntZlyOKoXD7JfQ042/k6cZPwpbBB0LhP3LNKCRA46o9ZvrxCJWvTx55ZLbla+b5hoI/pYvfwSNn9ympSzddRif9Sbmfu1eXX2nuyQ5gHJv2fbX0uytouSYhZxSdji1dcKBMC6ltC3odEo2q05maGqRSzfGth97ok= angus.clinch@gmail.com' > /home/ansible/.ssh/authorized_keys",
      "chmod 0600 /home/ansible/.ssh/authorized_keys",
      "chown -R ansible:ansible /home/ansible/",
      "sudo service sshd restart",
      "sudo sync"
    ]
  }

  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}