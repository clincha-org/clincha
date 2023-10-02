ksniff
=========

Install ksniff on a kubernetes cluster

Requirements
------------

Kubernetes cluster
kubectl

Role Variables
--------------

N/A

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
