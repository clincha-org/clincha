# Deployment

This is the end-to-end process for deploying out the clinch-home cloud.

## Packer template

[//]: # (TODO)

- Local network access to the server
- Running the packer template when you can connect to the Proxmox server directly
- Setting up the template

## Creating the virtual infrastructure

Run the "create" workflow in this repository. To do this, go to the create [actions page](https://github.com/clincha/clinch-home/actions/workflows/create.yml) of the clinch-home repository. Press the "Run workflow" button and then the same named green button that appears.

![clinch-home-create-workflow.png](img/clinch-home-create-workflow.png)

The run will take around 15 minutes and at the end there will be 4 servers created on the Proxmox host in Geddes. 

## Setup network access

Go to the [Unifi portal](https://unifi.ui.com/dashboard) and select the Geddes network.

![clinch-home-unifi-dashboard.png](img/clinch-home-unifi-dashboard.png)

On the left click "Settings" > "Firewall & Security" and scroll down to the "Port Forwarding" section. Using the "Create New Forwarding Rule" or by editing an existing rule make sure this rule exists:

```text
Name: GitHub Runner SSH
Enable Forward Rule: Enable
From: Any
Port: 16001
Forward IP: 192.168.2.161
Forward Port: 22
Protocol: Both
Logging: Enable
```

## Configuring the hosts

### Configuring virtual GitHub runner

Once that's completed then the first step is to sort out the GitHub runner that runs on the virtual machine on the Proxmox host. Go to the [runners](https://github.com/clincha/clinch-home/settings/actions/runners) page for the clinch-home repository and press "New self-hosted runner". Select "Linux" as the OS and keep the instructions on the page while we connect to the host.

Open a terminal and SSH into the server. **Navigate to the /usr/local/bin directory** so that [SELinux doesn't block](https://serverfault.com/questions/957084/failed-at-step-exec-spawning-permission-denied) the service script from being run. Run the commands from the GitHub help page. After running the first command in the "configure" section dependencies will likely need to be installed. Run this command:

`sudo ./bin/installdependencies.sh`

Finally, instead of running the run script, start a service instead by running the following:

`sudo ./svc.sh install`

`sudo ./svc.sh start`

### Configuring Kubernetes