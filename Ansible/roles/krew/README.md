Krew
=========

Use the Krew install guide script to install Krew 

Requirements
------------

git
kubectl


Role Variables
--------------

user: kubernetes
home_dir: "/home/{{ user }}"
bashrc: "{{ home_dir }}/.bashrc"

Dependencies
------------

N/A

Example Playbook
----------------

```yaml
- name: Install ksniff
  hosts: kube_control_plane
  roles:
    - role: krew
    - role: ksniff

```

License
-------

BSD

Author Information
------------------

Angus Clinch (angus.clinch@gmail.com)
