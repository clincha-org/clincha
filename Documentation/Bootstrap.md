# Bootstrap the Kubernetes Cluster

This document outlines the steps needed to get my Kubernetes cluster started.

## Prerequisites

- Three Proxmox hosts
- Wireguard VPN set up to the router
- GitHub workflow setup

## Order of operations

| Step                                                       |
|------------------------------------------------------------|
| Provision the VMs using Terraform                          |
| Run the Ansible playbook to configure the nodes            |
| Run the Ansible playbook to install Kubernetes             |
| Kubeconfig file copied to local machine and GitHub secrets |
| Restore Longhorn volumes from backup                       |
| Flux installs the services and application                 |
