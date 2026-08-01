# lon01

Proxmox hypervisor, London. Hosts `k8s-lon-1` and the `dns-lon-1` resolver.
Captured 2026-08-01.

| | |
|---|---|
| Management IP | 10.2.2.11 (vmbr0, 1GbE) |
| Access | `ssh root@10.2.2.11`, password in Bitwarden `Proxmox - root` |
| OS | Proxmox VE 9.2.6, kernel 7.0.2-2-pve |
| Firmware | HP BIOS Q26 Ver. 02.16.00, 15 Apr 2021. UEFI boot, Secure Boot disabled |
| Out-of-band | None enabled (see [Expansion](#expansion-slots)) |

This node runs a **different Proxmox major version** from the Hawkfield nodes (9.2.6 vs 8.4.19)
on a much newer kernel. Worth reconciling before any cross-site clustering work.

## Chassis and board

| | |
|---|---|
| System | HP EliteDesk 705 G4 DM 65W (TAA) — 1L "mini desktop" |
| System serial | MXL9332F80 |
| Board | HP 83E9, KBC version 07.D1.00 |
| Board serial | PHEMT0D8JCB2ML |
| Chipset | AMD 300 series (Promontory) |

A 1L mini chassis with an external 65W power brick. Everything about expansion on this box is
constrained by that form factor, not by the board.

## CPU

| | |
|---|---|
| Model | AMD Ryzen 5 PRO 2400G with Radeon Vega Graphics (Raven Ridge) |
| Socket | AM4, populated 1 of 1 |
| Cores / threads | 4 / 8 |
| Clocks | 3.6 GHz base, 3.9 GHz max |
| Virtualisation | AMD-V |

Socketed AM4, so a CPU upgrade is physically possible, but HP's BIOS whitelist and the 65W brick
plus 1L cooling put a hard ceiling on what is sensible. A Ryzen 5 PRO 3400G is the usual
drop-in.

## Memory

16 GiB DDR4 SODIMM, **non-ECC**, both slots populated. Board maximum is 32 GiB.

| Slot | Size | Part | Speed |
|------|------|------|-------|
| DIMM1 | 8 GB | Hynix HMA81GS6JJR8N-VK | 2667 MT/s |
| DIMM3 | 8 GB | Hynix HMA81GS6JJR8N-VK | 2667 MT/s |

A matched pair running at rated speed. Doubling to 32 GiB means replacing both with 2× 16 GiB
SODIMMs — the cheapest meaningful upgrade available to this node, which was at 5.7 GiB used of
14 GiB at capture.

## Storage

| Device | Model | Size | Attach | Use | Health |
|--------|-------|------|--------|-----|--------|
| nvme0n1 | Samsung MZVLB256HAHQ-000H7 (PM981) | 256 GB | M.2 SSD slot, PCIe 3.0 x4 | Proxmox root + `local-lvm` | OEM drive |
| sda | P3-1TB | 1 TB | SATA port 1, 2.5" bay | secondary | 6,678 power-on hours, negotiated 3 Gb/s |

Both attach points are used: one M.2 SSD socket and one 2.5" SATA bay is all the chassis has.
`sda` trains at SATA 3 Gb/s — normal for this chassis' SATA flex cable, not necessarily a fault.
Adding capacity here means replacing a drive, not adding one.

`zpool list` reports no ZFS pools; storage is `local` plus LVM-thin `local-lvm`.

## Expansion slots

| Slot (DMI label) | Reported | Occupant |
|------------------|----------|----------|
| Slot3 / M2 SSD | PCIe 3.0 x4 | Samsung PM981 NVMe |
| Slot2 / M2 WLAN/BT | PCIe 3.0 x1 | **free** |
| Slot1 / DGPU PCIEXP | PCIe 3.0 x8 | **reported free** |

The x8 "DGPU" slot is a firmware artifact of the shared 705 G4 board design — the DM (mini)
chassis has no riser or space for a card, so treat it as unusable without confirming physically.
The free M.2 WLAN slot is real and takes an A/E-key card (WiFi, or a Coral TPU-style accelerator).

The board also exposes a Realtek RTL8111xP with an IPMI-interface function and two UARTs, which
is HP's optional management path; nothing is configured on it today.

## Network

| Interface | Hardware | Link | Bridge | Address |
|-----------|----------|------|--------|---------|
| eno1 | Realtek RTL8111/8168 onboard | 1GbE, up | vmbr0 | 10.2.2.11/24, gw 10.2.2.1 |

Single 1GbE port, standard MTU. No 10G at this site.

## Guests

| VMID | Name | Type | vCPU | RAM | Disks |
|------|------|------|------|-----|-------|
| 111 | k8s-lon-1 | VM, running | 4 | 8 GiB | 50 GB + 100 GB `local-lvm` |
| 131 | dns-lon-1 | LXC, running | 2 | 2 GiB | 8 GB `local-lvm` |
| 101 | ubuntu2404 | VM template, stopped | 2 | 4 GiB | 50 GB |

The two running guests commit 10 GiB of the host's 14 GiB usable.

## Needs a physical check

- Confirm the 65W external power brick is the original and rated for any CPU change.
- Confirm there is genuinely no PCIe riser fitted (firmware claims a x8 slot).
- Dust/thermals: 1L chassis with a 65W APU, no fan telemetry exposed to the OS.
