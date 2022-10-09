# Swapping SSH keys

## Get a key

1. Login to Edinburgh Proxmox host as root
2. Navigate to /root/keys
3. Generate the key

```bash
ssh-keygen -t ed25519 -f /root/keys/clincha.key -C "angus.clinch@gmail.com"
ssh-keygen -t ed25519 -f /root/keys/ansible.key -C "ansible"
```

## Distribute keys

### Copy to Bristol

Don't forget to remove the old keys if necessary.

#### Node 1

```bash
scp -i /root/.ssh/clincha.key /root/keys/clincha.key.pub root@192.168.1.12:/root/.ssh/clincha.key.pub
ssh -i /root/.ssh/clincha.key root@192.168.1.12
cat /root/.ssh/clincha.key.pub >> /root/.ssh/authorized_keys
exit
```

#### Node 2

Node 2 should have already been updated thanks to Proxmox. However, if not do the following.

```bash
scp -i /root/.ssh/clincha.key /root/keys/clincha.key.pub root@192.168.1.11:/root/.ssh/clincha.key.pub
ssh -i /root/.ssh/clincha.key root@192.168.1.11
cat /root/.ssh/clincha.key.pub >> /root/.ssh/authorized_keys
exit
```

### Copy to Edinburgh

Don't forget to remove the old keys if necessary.

```bash
cp /root/keys/clincha.key /root/.ssh/clincha.key
cp /root/keys/clincha.key.pub /root/.ssh/clincha.key.pub
cat /root/keys/clincha.key.pub >> /root/.ssh/authorized_keys
```

### Other destinations

- Laptops
- Desktop
- [GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- [GitHub Actions](https://github.com/clincha/clinch-home/settings/secrets/actions)
- Packer
- Terraform
- Vault
