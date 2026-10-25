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

Install compilers

```bash
sudo apt update; sudo apt install make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

### Virtual environment

```bash
pyenv install 3.13
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
ansible-playbook kubernetes.yml -i inventory/hawkfield.proxmox.yml --vault-password-file vault --become
```

## Proxmox hosts

- Connect to the proxmox host as root and install sudo.
- Create the Ansible user and use the `Ansible` password in BitWarden
- Update the `inventory/proxmox.yml` file with the proxmox host IP address.
- Create the vault password file and use the `Ansible Vault` password in BitWarden.
- Run the `proxmox.yml` playbook. `ansible-playbook proxmox.yml -i inventory/proxmox.yml --vault-password-file vault`

## Troubleshooting

MAKE SURE KUBERNETES VERSION IS SUPPORTED BY KUBESPRAY! CHECK THE RELEASE NOTES!
## Workstation monitoring

The desktop and laptop are off most of the time, so they are not in an inventory or CI. Run the playbook on the machine itself; it installs Alloy and ships metrics and journald logs to the same Prometheus and Loki as the servers (`site="workstation"`).

```bash
sudo apt install -y pipx git
git clone https://github.com/clincha-org/clincha.git && cd clincha/Ansible
pipx run --spec ansible-core ansible-playbook workstations.yml --ask-become-pass
```

Samples are dropped while the machine is off or away from the LAN.
