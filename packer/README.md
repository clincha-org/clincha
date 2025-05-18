# Packer - Ubuntu 24.04

Create the `variables.auto.pkrvars.hcl` file to inject the passwords.

```hcl
proxmox_password = "" # Password for root on proxmox
ssh_password = "" # Password for ansible user on proxmox



Each host needs its own run

`packer build -var-file=hawk01.pkrvars.hcl .`

`packer build -var-file=hawk02.pkrvars.hcl .`

`packer build -var-file=hawk03.pkrvars.hcl .`
