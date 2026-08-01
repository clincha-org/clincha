# hawk01

Proxmox hypervisor, Hawkfield. Hosts `k8s-hawk-1` and the `dns-hawk-1` resolver.
Captured 2026-08-01.

| | |
|---|---|
| Management IP | 10.1.2.11 (vmbr0, 1GbE) / 10.1.2.21 (vmbr1, 10G) |
| Access | `ssh root@10.1.2.11`, password in Bitwarden `Proxmox - root` |
| OS | Proxmox VE 8.4.19, kernel 6.8.12-32-pve |
| Firmware | AMI BIOS 4631, 14 Jan 2025. UEFI boot, Secure Boot disabled |
| Out-of-band | None — consumer board, no BMC/IPMI |

## Chassis and board

| | |
|---|---|
| Board | ASUS PRIME B450M-A II, rev X.0x, micro-ATX |
| Board serial | 211092947903200 |
| System/chassis | Generic desktop tower, SMBIOS strings unset ("System Product Name") |
| Chipset | AMD B450 |

The board reports no system or chassis identity, so case, PSU and cooler are unrecorded. See
[Needs a physical check](#needs-a-physical-check).

## CPU

| | |
|---|---|
| Model | AMD Ryzen 5 5600GT with Radeon Graphics (Cezanne) |
| Socket | AM4, populated 1 of 1 |
| Cores / threads | 6 / 12 |
| Clocks | 3.6 GHz base, 4.65 GHz max |
| L3 cache | 16 MiB |
| Virtualisation | AMD-V, single NUMA node |

Upgrade path: any AM4 CPU the B450 board's BIOS supports, up to a Ryzen 9 5950X (16c/32t).
Dropping the integrated graphics would make the GT 730 mandatory rather than optional.

## Memory

80 GiB DDR4, **non-ECC**, all 4 slots populated. Board maximum is 128 GiB.

| Slot | Size | Part | Rated | Running at |
|------|------|------|-------|------------|
| DIMM_A1 | 8 GB | Corsair CMK16GX4M2Z3600C18 | 3600 | 2133 MT/s |
| DIMM_A2 | 32 GB | Corsair CMK32GX4M1A2666C16 | 2666 | 2133 MT/s |
| DIMM_B1 | 8 GB | Corsair CMK16GX4M2Z3600C18 | 3600 | 2133 MT/s |
| DIMM_B2 | 32 GB | Corsair CMK32GX4M1A2666C16 | 2666 | 2133 MT/s |

Two mismatched kits, so the whole set falls back to 2133 MT/s — roughly half the rated speed of
the faster kit. Going to 128 GiB means replacing all four sticks with a matched 4× 32 GiB kit;
going to a matched 2× 32 GiB kit would cost 16 GiB but run at full speed in dual channel.

## Storage

| Device | Model | Size | Attach | Use | Health |
|--------|-------|------|--------|-----|--------|
| nvme0n1 | GIGABYTE GP-GSM2NE3128GNTD | 128 GB | M.2, PCIe 3.0 x4 | Proxmox root + `local-lvm` thin pool | **55% life used**, 41.8 TB written |
| sda | KINGSTON SA400S37120G | 120 GB | SATA port 1 | ZFS `fast` mirror | 29,579 power-on hours |
| sdb | KINGSTON SA400S37120G | 120 GB | SATA port 2 | ZFS `fast` mirror | 29,521 power-on hours |

- `fast` — ZFS mirror, 111 GB, 10% used, ONLINE, last scrub clean 12 Jul 2026. Shared storage
  definition covers hawk01/02/03.
- `local-lvm` — LVM-thin on the NVMe, 53.9 GB pool.

**Free attach points:** 4 of 6 SATA connectors (`SATA6G_1`–`SATA6G_6` per firmware) and no free
M.2 — the single M.2 socket is occupied. Adding bulk storage means SATA, or an NVMe on a x1
adapter in the free PCIe slot (which would cap at ~500 MB/s).

The boot NVMe at 55% endurance is the thing to watch on this node.

## Expansion slots

Firmware reports three slots. The labels are unreliable — the measured link widths below say
what is really where.

| Slot (DMI label) | Reported | Occupant | Measured link |
|------------------|----------|----------|---------------|
| PCIEX16 | x16, long | Intel 82599ES (X520) dual SFP+ 10G | Gen2 x8 |
| PCIEX1_2 | x1, short | NVIDIA GK208B GeForce GT 730 (+ HDMI audio) | Gen1 x1 (downgraded) |
| PCIEX1_1 | x1, short | **free** | — |

The GT 730 negotiating x1 confirms it sits in a x1 slot, not the x16. One x1 slot is free; a x4
or wider card has nowhere to go unless the GT 730 comes out and the 5600GT's integrated graphics
takes over display duties.

## Network

| Interface | Hardware | Link | Bridge | Address |
|-----------|----------|------|--------|---------|
| enp8s0 | Realtek RTL8111/8168 onboard | 1GbE, up | vmbr0 | 10.1.2.11/24, gw 10.1.2.1 |
| enp1s0f0 | Intel 82599ES port 0 | 10G SFP+ fibre, up | vmbr1 | 10.1.2.21/24 |
| enp1s0f1 | Intel 82599ES port 1 | down, **unused** | — | — |

Both bridges run MTU 9000. `/etc/network/interfaces` still carries stale stanzas for
`enp9s0f0`/`enp9s0f1` from an earlier PCIe layout — interface names are pinned by name in that
file, so any board or NIC change breaks networking on reboot unless the file is updated first.

The second X520 port is free if a second 10G link or a LACP bond is ever wanted.

## Guests

| VMID | Name | Type | vCPU | RAM | Disks |
|------|------|------|------|-----|-------|
| 111 | k8s-hawk-1 | VM, running | 10 | 64 GiB | 50 GB `local-lvm` + 100 GB `fast` |
| 131 | dns-hawk-1 | LXC, running | 2 | 2 GiB | 8 GB `local-lvm` |
| 101 | ubuntu2404 | VM template, stopped | 2 | 4 GiB | 50 GB |

64 GiB of the host's 80 GiB is committed to `k8s-hawk-1`, leaving little headroom — memory is
the binding constraint on this node, not CPU.

## Needs a physical check

- PSU make, model and wattage; number of spare SATA power and PCIe power connectors.
- Case model and how many 2.5"/3.5" drive bays are free.
- CPU cooler and case fan count (board has CPU_FAN, CHA_FAN1, CHA_FAN2 headers).
- Whether the free x1 slot is open-ended (it accepts a longer card only if it is).
- TPM header is present and unpopulated.
