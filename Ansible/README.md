# Ansible 

## Proxmox hosts

- Connect to the proxmox host as root and install sudo.
- Create the Ansible user and use the `Ansible` password in BitWarden
- Update the `inventory/proxmox.yml` file with the proxmox host IP address.
- Create the vault password file and use the `Ansible Vault` password in BitWarden.
- Run the `proxmox.yml` playbook. `ansible-playbook proxmox.yml -i inventory/proxmox.yml --vault-password-file vault`