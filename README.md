# clinch-home

#### Status

[![clinch-home ansible nightly](https://github.com/clincha/clinch-home/actions/workflows/ansible-nightly.yml/badge.svg)](https://github.com/clincha/clinch-home/actions/workflows/ansible-nightly.yml)
[![nginx-proxy](https://github.com/clincha/clinch-home/actions/workflows/nginx.yml/badge.svg)](https://github.com/clincha/clinch-home/actions/workflows/nginx.yml)

## Overview

### Ubuntu 20.04

darling: 192.168.1.12  
mandela: 192.168.1.13  
turing: 192.168.1.14

### TrueNAS

freenas: 192.168.1.10

### idrac

freenas: 192.168.1.11 (**UNKNOWN PASSWORD**)  
turing: **NOT WORKING**

## Improvements

### VPN
- Point to point connection

### Traefik
- Applications
- Internal resources
- SSL

### ELK
- Get the ELK stack working and available
- Monitor
  - Kubernetes health
  - Server health
  - Application health
- Logs

### Hardware

- Get idrac working on all the servers
- Server room

### Kubernetes

- Run the Kubernetes config against the servers nightly
- Make a new node pipeline to configure a new node and add it to the cluster
    - Cloud node
    - Raspberry Pi node
    - Ubuntu node

### Ansible

- Turning SWAP off runs a change even when SWAP is already disabled. Can we make this not run a change if the command
  has already been run?
- Reloading sysctl runs a change even when the parameters are already loaded. Can we change this so that no change is
  made if the parameters already exist?

## Secrets

- KUBECONFIG
- ANSIBLE_PK
- DOCKER_PASSWORD
