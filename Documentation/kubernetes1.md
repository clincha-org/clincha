# Automation attempt at kubernetes

## Manual again (but less)

I struggled to get Ansible to install Kubernetes when I was running my worker nodes on bare metal. I needed to be able
to iterate from a clean slate but the OS always had all my previous attempts. I never knew which change had tweaked the
settings just the right way, or if it was a combination multiple. I installed a hypervisor on the physical servers, used
Packer to create an automated template, leveraged Terraform to deploy copies of the template and Ansible playbooks to
configure the OS ready for applications. Each had a workflow that ran in using the GitHub actions API.

### packer

Run through the first time OS installation process, configure kickstart parameters and create a template for use in
Proxmox (the hypervisor I chose).

This workflow has a unique issue. The kickstart file is published over the network for the node to pick it up. However,
the GitHub runner isn't on the same network as the VM it's working with on the Proxmox node. This means that I can't run
the build on the GitHub hosted runner. I have to make a custom runner on the same network as the hypervisor and connect
it to GitHub. [Not ideal...](https://github.com/clincha/clinch-home/issues/11)

### terraform

Use the templates created by Packer and inject cloud-init settings to customise the servers on first boot. Connect using
the credentials set by Packer and set more configuration (hostname, network, tags).

terraform-destroy is a secondary workflow used to destroy the instances, but at the moment it doesn't do that
cleanly. [It should have functionality to unsubscribe to RedHat subscription services](https://github.com/clincha/clinch-home/issues/12)
.

### ansible

Ansible uses the tags set by Terraform and a dynamic inventory pointing at Proxmox to configure the hosts. All servers
have a "base" tag assigned to them. Ansible will configure the server with configuration outlined in the site YAML file.
Tags can be given to hosts that cause Ansible to install an application. I'm going to use this feature to create a
Kubernetes cluster on a group of hosts and to create a local GitHub runner.

### Automate it already

I needed to test the process of installing the cluster before I try to automate it. I don't think this time was any
different to running it on physical servers, but I did find a tutorial that nudged me in the right direction regarding
container runtimes. When I was installing kubernetes on physical hardware I used containerd as the container runtime.
However, I should've been using cri-o instead. It's a product from RedHat, and it's designed to run on my OS which made
the cluster much simpler to bring up.

I used [this tutorial](https://www.linuxtechi.com/how-to-install-kubernetes-cluster-rhel/) but skipped some networking.
Firewalld wasn't running on my OS, so I skipped those settings and I didn't add hostnames to the host file, it seemed to
work fine with ip addresses. A lot of the Calico network stuff wasn't needed either. I guess that there was a lot of
sensible defaults going on when I did it.

Ran a test workload and this is the result:

````bash
[clincha@edi-kubeworker-1 ~]$ k get pods
NAME                     READY   STATUS    RESTARTS   AGE
busybox0                 1/1     Running   0          46s
````

It works! Now it's time to [write those steps into Ansible](https://github.com/clincha/clinch-home/issues/13), write a
workflow [encompassing Terraform and Ansible](https://github.com/clincha/clinch-home/issues/14) and then iterate.

## Automate it
