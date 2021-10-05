# clinch-home

#### Status

[![clinch-home ansible nightly](https://github.com/clincha/clinch-home/actions/workflows/ansible-nightly.yml/badge.svg)](https://github.com/clincha/clinch-home/actions/workflows/ansible-nightly.yml)
[![elk](https://github.com/clincha/clinch-home/actions/workflows/elk.yml/badge.svg)](https://github.com/clincha/clinch-home/actions/workflows/elk.yml)

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

### Ansible Playbook

- Turning SWAP off runs a change even when SWAP is already disabled. Can we make this not run a change if the command
  has already been run?
- Reloading sysctl runs a change even when the parameters are already loaded. Can we change this so that no change is
  made if the parameters already exist?

## Secrets

- KUBECONFIG
- ANSIBLE_PK