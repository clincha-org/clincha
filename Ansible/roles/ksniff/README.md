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

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
