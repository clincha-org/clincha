# Packer - Ubuntu 24.04

Create the `variables.auto.pkrvars.hcl` file to inject the passwords.

```hcl
proxmox_password = "" # Password for root on proxmox
ssh_password = "" # Password for ansible user on proxmox
```

Change to the `ubuntu2404` directory. Each host needs its own run

`packer build -force -var-file=hawk01.pkrvars.hcl .`
`packer build -force -var-file=hawk02.pkrvars.hcl .`
`packer build -force -var-file=hawk03.pkrvars.hcl .`
