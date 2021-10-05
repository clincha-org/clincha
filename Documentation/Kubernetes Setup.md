## Kubernetes Setup
## Ports
The master node will need port **6443** to be open to access the kubctl command

## Improvements
### Ansible Playbook
- Turning SWAP off runs a change even when SWAP is already disabled. Can we make this not run a change if the command has already been run?
- Reloading sysctl runs a change even when the parameters are already loaded. Can we change this so that no change is made if the parameters already exist?