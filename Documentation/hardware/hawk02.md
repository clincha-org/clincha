# hawk02

Proxmox hypervisor, Hawkfield. Hosts `k8s-hawk-2` and `claude-hawk-1` (Dave).
Captured 2026-08-01.

| | |
|---|---|
| Management IP | 10.1.2.12 (vmbr0, 1GbE) / 10.1.2.22 (vmbr1, 10G) |
| Access | `ssh root@10.1.2.12`, password in Bitwarden `Proxmox - root` |
| OS | Proxmox VE 8.4.19, kernel 6.8.12-32-pve |
| Firmware | AMI BIOS 4631, 14 Jan 2025. UEFI boot, Secure Boot disabled |
| Out-of-band | None — consumer board, no BMC/IPMI |

## Chassis and board

| | |
|---|---|
| Board | ASUS PRIME B450M-A II, rev X.0x, micro-ATX |
| Board serial | 250250960901942 |
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

Unlike hawk01 and hawk03, the integrated Radeon graphics is enabled here — the host exposes two
render nodes (`/dev/dri/card1` and `card2`, the iGPU and the GT 730). That makes hawk02 the only
node currently able to pass a GPU through for hardware transcoding without a BIOS change.

## Memory

80 GiB DDR4, **non-ECC**, all 4 slots populated. Board maximum is 128 GiB.

| Slot | Size | Part | Rated | Running at |
|------|------|------|-------|------------|
| DIMM_A1 | 8 GB | Corsair CMK16GX4M2Z3600C18 | 3600 | 2133 MT/s |
| DIMM_A2 | 32 GB | Corsair CMK32GX4M1A2666C16 | 2666 | 2133 MT/s |
| DIMM_B1 | 8 GB | Corsair CMK16GX4M2Z3600C18 | 3600 | 2133 MT/s |
| DIMM_B2 | 32 GB | Corsair CMK32GX4M1A2666C16 | 2666 | 2133 MT/s |

Mismatched kits clock the whole set down to 2133 MT/s. At capture the host had 71 GiB of 77 GiB
in use — this is the tightest node in the cluster for memory.

## Storage

| Device | Model | Size | Attach | Use | Health |
|--------|-------|------|--------|-----|--------|
| nvme0n1 | Crucial CT1000P510SSD8 | 1 TB | M.2, PCIe 3.0 x4 | Proxmox root + `local-lvm` (794 GB thin pool) | 2% life used, 20.8 TB written |
| sda | Patriot Burst Elite 120GB | 120 GB | SATA port 1 | **unused** — stale ZFS label | 1,486 power-on hours |
| sdb | SanDisk Ultra | 32 GB | USB | Proxmox installer stick left plugged in | — |

Two things differ from the other nodes:

- **The `fast` ZFS mirror does not exist here.** `sda` carries a label for pool `fast` as a
  member of a two-disk mirror, but its partner is gone and `zpool import` finds nothing —
  the SSD was replaced (1,486 hours on the current one) and the pool was never rebuilt.
  `storage.cfg` still lists hawk02 as a `fast` node, and `k8s-hawk-2`'s 100 GB data disk sits on
  `local-lvm` while hawk01/hawk03 put theirs on `fast`. Either rebuild the mirror with a second
  SSD, or drop hawk02 from the `fast` node list.
- The 1 TB Crucial P510 is a PCIe 5.0 drive running at Gen3 x4 — the board's ceiling. It is the
  largest and healthiest boot drive in the cluster, and the obvious donor if hawk01's 55%-worn
  NVMe needs replacing.

**Free attach points:** 5 of 6 SATA connectors, no free M.2.

## Expansion slots

| Slot (DMI label) | Reported | Occupant | Measured link |
|------------------|----------|----------|---------------|
| PCIEX16 | x16, long | Intel 82599ES (X520) dual SFP+ 10G | Gen2 x8 |
| PCIEX1_2 | x1, short | NVIDIA GK208B GeForce GT 730 (+ HDMI audio) | Gen1 x1 (downgraded) |
| PCIEX1_1 | x1, short | **free** | — |

## Network

| Interface | Hardware | Link | Bridge | Address |
|-----------|----------|------|--------|---------|
| enp8s0 | Realtek RTL8111/8168 onboard | 1GbE, up | vmbr0 | 10.1.2.12/24 |
| enp1s0f0 | Intel 82599ES port 0 | 10G SFP+ fibre, up | vmbr1 | 10.1.2.22/24 |
| enp1s0f1 | Intel 82599ES port 1 | down, **unused** | — | — |

Interface names are pinned by name in `/etc/network/interfaces`; update it before any board or
NIC swap or the node comes back unreachable.

## Guests

| VMID | Name | Type | vCPU | RAM | Disks |
|------|------|------|------|-----|-------|
| 112 | k8s-hawk-2 | VM, running | 10 | 64 GiB | 50 GB + 100 GB, both `local-lvm` |
| 122 | claude-hawk-1 | VM, running | 4 | 8 GiB | 50 GB + 100 GB `local-lvm` |
| 102 | ubuntu2404 | VM template, stopped | 2 | 4 GiB | 50 GB |

## Needs a physical check

- PSU make, model and wattage; spare SATA power connectors.
- Case model and free drive bays.
- Whether the USB installer stick and USB keyboard should stay connected.
- Whether the free x1 slot is open-ended.
