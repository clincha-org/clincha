# Ansible 

## Running locally

### Pyenv

Install Pyenv so we can use the latest Python version.

```bash
curl -fsSL https://pyenv.run | bash
```

Update your shell configuration files to load pyenv automatically.

```bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
```

```bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
echo 'eval "$(pyenv init - bash)"' >> ~/.profile
```

### Virtual environment

```bash
pyenv virtualenv 3.13 ansible
pyenv activate ansible
```

### Install dependencies

```bash
pip install -r requirements.txt
```

```bash
ansible-galaxy install -r galaxy-requirements.yml
```

### Load ssh keys

```bash
eval `ssh-agent -s`
ssh-add ~/.ssh/ansible
```

### Run Ansible

```bash
ansible-playbook kubernetes.yml -i inventory/london.proxmox.yml --vault-password-file vault --become
```

## Proxmox hosts

- Connect to the proxmox host as root and install sudo.
- Create the Ansible user and use the `Ansible` password in BitWarden
- Update the `inventory/proxmox.yml` file with the proxmox host IP address.
- Create the vault password file and use the `Ansible Vault` password in BitWarden.
- Run the `proxmox.yml` playbook. `ansible-playbook proxmox.yml -i inventory/proxmox.yml --vault-password-file vault`

## Troubleshooting

MAKE SURE KUBERNETES VERSION IS SUPPORTED BY KUBESPRAY! CHECK THE RELEASE NOTES!