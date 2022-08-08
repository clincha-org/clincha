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

[This issue](https://github.com/clincha/clinch-home/issues/13) documents what code changes needed to happen. The first time I wrote this code (for physical servers) I wrote with containerd as my container runtime. Looking through some tutorials for Kubernetes on RHEL8 this time, I learned that cri-o is written by RedHat for RHEL/CentOS. Containerd needed to go, cri-o was the chosen one. I'd written the code with modularity in mind last time, so it was a targeted change to get cri-o working instead. I had loads of existing code to keep docker alive which should have been a sign I was doing something wrong. 

I'm able to iterate rapidly with this new environment. Having the ability to recreate everything quickly (15 minutes) means I can have a blank slate, frequently. Most of the time I don't _need_ a blank slate, the infrastructure is already in place and the runs only take 5 minutes to check everything. There are a couple of issues that need sorting:

- Terraform changes lots of disk and network config for the VM every run. This is slowing down the terraform pipeline.
- It's a manual process to create a master and slave nodes
- Modularise the GitHub workflows. Reuse code

## Onwards

Time to get started with the applications. I've got a solid environment, now time to write some code. I'll be jumping into Kubernetes and running an Elastic Stack. Alongside that I can look at writing code (Python, Java, Go?, Kotlin?) for the application layer to work with an API and pass data into Elastic.

- Create a Logstash instance (might not be needed)
- Create the Elastic instance
- Create a Kibana instance

- Write application interacting with API
- Create containerised package for the application
- Deploy the application on the cluster