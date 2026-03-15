# clincha

This is my personal cloud. Two sites — Hawkfield (Bristol) and London — running physical servers that I built myself. The full stack goes Proxmox → Packer → Terraform → Ansible → Kubernetes → Flux CD. It's more than a home lab but probably less than a cloud. I want to be the ultimate full stack developer, not just understanding the code that runs but the complete environment it runs in, right down to the electrons leaving the plug.

## Infrastructure

```mermaid
graph TB
    subgraph "Hawkfield (Bristol)"
        subgraph "Proxmox Cluster"
            hawk01[hawk01]
            hawk02[hawk02]
            hawk03[hawk03]
        end
        subgraph "K8s Cluster (3x 10-core, 64GB)"
            kh1[k8s-hawk-1<br/>10.1.2.101]
            kh2[k8s-hawk-2<br/>10.1.2.102]
            kh3[k8s-hawk-3<br/>10.1.2.103]
        end
        claw[claw-hawk-1<br/>10.1.2.122<br/>OpenClaw]
        hawk01 --> kh1
        hawk02 --> kh2
        hawk02 --> claw
        hawk03 --> kh3
        subgraph "Hawkfield Workloads"
            h_infra[nginx-ingress / MetalLB<br/>Longhorn / Cert-Manager<br/>Prometheus + Grafana<br/>Uptime Kuma]
            h_apps[Homepage / Factorio<br/>Satisfactory]
        end
    end

    subgraph "London"
        lon01[lon01]
        subgraph "K8s Cluster (3x 4-core, 4GB)"
            kl1[k8s-lon-1<br/>10.2.0.101]
            kl2[k8s-lon-2<br/>10.2.0.102]
            kl3[k8s-lon-3<br/>10.2.0.103]
        end
        lon01 --> kl1
        lon01 --> kl2
        lon01 --> kl3
        subgraph "London Workloads"
            l_infra[Traefik / MetalLB<br/>Longhorn / Cert-Manager<br/>Elastic Operator]
            l_apps[Homepage<br/>Elastic Finance]
        end
    end

    subgraph "CI/CD (GitHub Actions)"
        gha[GitHub Actions<br/>ubuntu-latest]
        ts[Tailscale VPN]
        gha --> ts
    end

    ts --> hawk01
    ts --> lon01

    subgraph "GitOps"
        flux[Flux CD v2.7.5]
        flux --> kh1
        flux --> kl1
    end
```

## Workflow Status

### Infrastructure

[![Packer Build](https://github.com/clincha-org/clincha/actions/workflows/packer.yaml/badge.svg)](https://github.com/clincha-org/clincha/actions/workflows/packer.yaml)
[![Terraform Apply](https://github.com/clincha-org/clincha/actions/workflows/terraform.yaml/badge.svg)](https://github.com/clincha-org/clincha/actions/workflows/terraform.yaml)
[![Terraform Plan (PR)](https://github.com/clincha-org/clincha/actions/workflows/terraform-plan.yaml/badge.svg)](https://github.com/clincha-org/clincha/actions/workflows/terraform-plan.yaml)
[![Ansible Base Configuration](https://github.com/clincha-org/clincha/actions/workflows/ansible-base.yaml/badge.svg)](https://github.com/clincha-org/clincha/actions/workflows/ansible-base.yaml)

### Maintenance

[![Ansible Update Kubernetes](https://github.com/clincha-org/clincha/actions/workflows/ansible-update-k8s.yaml/badge.svg)](https://github.com/clincha-org/clincha/actions/workflows/ansible-update-k8s.yaml)
[![Ansible Update Proxmox](https://github.com/clincha-org/clincha/actions/workflows/ansible-update-proxmox.yaml/badge.svg)](https://github.com/clincha-org/clincha/actions/workflows/ansible-update-proxmox.yaml)

### CI/CD

[![Ansible Lint](https://github.com/clincha-org/clincha/actions/workflows/ansible-lint.yaml/badge.svg)](https://github.com/clincha-org/clincha/actions/workflows/ansible-lint.yaml)

## The Journey

From rack-mounting servers with a friend in London, to negotiating noise levels with my parents in Bristol, to finally getting Kubernetes clusters humming across both sites — the path here has been anything but straight. Read the full story in [Documentation/journey.md](Documentation/journey.md).
