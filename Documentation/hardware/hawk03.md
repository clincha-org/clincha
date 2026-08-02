# hawk03

Proxmox hypervisor, Hawkfield. Hosts `k8s-hawk-3`. Captured 2026-08-01.

| | |
|---|---|
| Management IP | 10.1.2.13 (vmbr0, 1GbE) / 10.1.2.23 (vmbr1, 10G) |
| Access | `ssh root@10.1.2.13`, password in Bitwarden `Proxmox - root` |
| OS | Proxmox VE 8.4.19, kernel 6.8.12-32-pve |
| Firmware | AMI BIOS 4631, 14 Jan 2025. UEFI boot, Secure Boot disabled |
| Out-of-band | None — consumer board, no BMC/IPMI |

## Chassis and board

| | |
|---|---|
| Board | ASUS PRIME B450M-A II, rev X.0x, micro-ATX |
| Board serial | 211092947901897 |
| System/chassis | Generic desktop tower, SMBIOS strings unset ("System Product Name") |
| Chipset | AMD B450 |

## CPU

| | |
|---|---|
| Model | AMD Ryzen 5 5600GT with Radeon Graphics (Cezanne) |
| Socket | AM4, populated 1 of 1 |
| Cores / threads | 6 / 12 |
| Clocks | 3.6 GHz base, 4.65 GHz max |
| L3 cache | 16 MiB |
| Virtualisation | AMD-V, single NUMA node |

## Memory

80 GiB DDR4, **non-ECC**, all 4 slots populated. Board maximum is 128 GiB.

| Slot | Size | Part | Rated | Running at |
|------|------|------|-------|------------|
| DIMM_A1 | 8 GB | Corsair CMK16GX4M2Z3600C18 | 3600 | 2133 MT/s |
| DIMM_A2 | 32 GB | Corsair CMK32GX4M1A2666C16 | 2666 | 2133 MT/s |
| DIMM_B1 | 8 GB | Corsair CMK16GX4M2Z3600C18 | 3600 | 2133 MT/s |
| DIMM_B2 | 32 GB | Corsair CMK32GX4M1A2666C16 | 2666 | 2133 MT/s |

## Storage

| Device | Model | Size | Attach | Use | Health |
|--------|-------|------|--------|-----|--------|
| nvme0n1 | GIGABYTE GP-GSM2NE3128GNTD | 128 GB | M.2, PCIe 3.0 x4 | Proxmox root + `local-lvm` thin pool | **47% life used**, 35.4 TB written |
| sda | GIGABYTE GP-GSTFS31120GNTD | 120 GB | SATA port 1 | ZFS `fast` mirror | 34,024 power-on hours |
| sdb | GIGABYTE GP-GSTFS31120GNTD | 120 GB | SATA port 2 | ZFS `fast` mirror | 34,016 power-on hours, link negotiated at 3 Gb/s |

- `fast` — ZFS mirror, 111 GB, 15% used, ONLINE, last scrub clean 12 Jul 2026.
- `sdb` has trained down to SATA 3 Gb/s rather than 6 Gb/s. Usually a cable or port issue and
  worth reseating next time the case is open; the drive itself reports SATA 3.2 capable.
- These two SSDs have ~34,000 hours (nearly 4 years) on them, the oldest drives in the cluster.

**Free attach points:** 4 of 6 SATA connectors, no free M.2.

## Expansion slots

| Slot (DMI label) | Reported | Occupant | Measured link |
|------------------|----------|----------|---------------|
| PCIEX16 | x16, long | Intel 82599ES (X520) dual SFP+ 10G | Gen2 x8 |
| PCIEX1_2 | x1, short | NVIDIA GK208B GeForce GT 730 (+ HDMI audio) | Gen1 x1 (downgraded) |
| PCIEX1_1 | x1, short | **free** | — |

## Network

| Interface | Hardware | Link | Bridge | Address |
|-----------|----------|------|--------|---------|
| enp8s0 | Realtek RTL8111/8168 onboard | 1GbE, up | vmbr0 | 10.1.2.13/24 |
| enp1s0f0 | Intel 82599ES port 0 | 10G SFP+ fibre, up | vmbr1 | 10.1.2.23/24 |
| enp1s0f1 | Intel 82599ES port 1 | down, **unused** | — | — |

`/etc/network/interfaces` also carries stale stanzas for `enp9s0f0`/`enp9s0f1` from an earlier
PCIe layout. Names are pinned there, so update the file before any board or NIC swap.

## Guests

| VMID | Name | Type | vCPU | RAM | Disks |
|------|------|------|------|-----|-------|
| 113 | k8s-hawk-3 | VM, running | 10 | 64 GiB | 50 GB `local-lvm` + 100 GB `fast` |
| 103 | ubuntu2404 | VM template, stopped | 2 | 4 GiB | 50 GB |

## Needs a physical check

- PSU make, model and wattage; spare SATA power connectors.
- Case model and free drive bays.
- The `sdb` SATA cable and port (link running at 3 Gb/s).
- Whether the free x1 slot is open-ended.
