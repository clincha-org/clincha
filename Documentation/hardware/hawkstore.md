# hawkstore

TrueNAS storage server, Hawkfield. Backs the whole homelab over NFS — Prometheus TSDB, Grafana,
Loki chunks, all media volumes. Captured 2026-08-01.

| | |
|---|---|
| IP | 10.1.2.10 (bond0, 10G) |
| BMC / IPMI | 10.1.2.9, static, MAC ac:1f:6b:4a:34:f6 |
| Access | Web UI + API. The SSH service listens on 22, but no user has an authorised key and `password_login_groups` is empty, so there is no shell access today. API key in Bitwarden `Hawkstore API key` (Bearer, user `dave`) |
| OS | TrueNAS 25.10.4 "Goldeye" Community Edition |
| Firmware | AMI BIOS 3.4a, 16 Aug 2021 |

## Chassis and board

| | |
|---|---|
| System | Supermicro SSG-6048R-E1CR36L (4U storage server) |
| System serial | S17496627B11491 |
| Chassis serial | C8470FG34NA0299 |
| Board | Supermicro X10DRH-iT rev 1.10 |
| Board serial | NM178S018578 |
| Chipset | Intel C612 |
| BMC | ASPEED AST2400 (graphics at 06:00.0), IPMI on a dedicated port |

The model designation is Supermicro's 36-bay platform (24 front + 12 rear 3.5" hot-swap bays).
**TrueNAS reports no SES enclosure**, so drive-to-bay mapping is not available from software —
the bays are almost certainly cabled straight to the HBAs rather than through an expander
backplane. Label the bays physically before pulling anything.

## CPU

| Socket | Model | Cores / threads | Clocks |
|--------|-------|-----------------|--------|
| SOCKET 0 | Intel Xeon E5-2667 v4 | 8 / 16 | 3.2 GHz base, 3.6 GHz turbo |
| SOCKET 1 | Intel Xeon E5-2667 v4 | 8 / 16 | 3.2 GHz base, 3.6 GHz turbo |

16 cores / 32 threads total, LGA2011-3, both sockets populated. Load average at capture was 0.67
— this box is nowhere near CPU-bound.

## Memory

128 GiB DDR4 ECC registered, **8 of 16 slots populated** (one DIMM per channel, 4 channels per
CPU). Multi-bit ECC active.

| Slots populated | Size each | Part | Speed |
|-----------------|-----------|------|-------|
| P1_DIMMA1, B1, C1, D1 (CPU1) | 16 GB | Micron 36ASF2G72PZ-2G3B1 | 2400 MT/s |
| P2_DIMME1, F1, G1, H1 (CPU2) | 16 GB | Micron 36ASF2G72PZ-2G3B1 | 2400 MT/s |

Free slots: **P1_DIMMA2/B2/C2/D2 and P2_DIMME2/F2/G2/H2** — 8 empty, 4 per CPU. Firmware reports
512 GB maximum per CPU (1 TB total with LRDIMMs). The cheap upgrade is another 8× 16 GB RDIMM
matching the existing Micron part, taking the box to 256 GiB and keeping one-DIMM-per-channel
symmetry across both CPUs. ZFS will use every byte of it as ARC.

## Storage

20 drives, all SATA, on three LSI SAS3008 HBAs plus the onboard AHCI controllers.

| Controller | SCSI host | Drives | Ports used |
|------------|-----------|--------|------------|
| LSI SAS3008 (CPU2 SLOT5/6/7) | host0 | sdd, sdf, sdg, sdh | 4 of 8 |
| LSI SAS3008 | host13 | sdi, sdj, sdk, sdl | 4 of 8 |
| LSI SAS3008 | host14 | sdm, sdn, sdo, sdp, sdq, sdr, sds, sdt | 8 of 8 |
| Onboard C612 AHCI (sSATA + SATA) | host6–9 | sda, sdb, sdc, sde | 4 of ~10 |

That leaves roughly 8 unused HBA ports and 6 unused onboard SATA ports — the enclosure has spare
bays, and the controllers have spare ports to drive them. Confirm the breakout cabling
physically before buying drives.

### Drives

| Device | Model | Size | Type | Pool | Temp |
|--------|-------|------|------|------|------|
| sda | Crucial CT500BX500SSD1 | 500 GB | SSD | userstore | 43 °C |
| sdb | Crucial CT500BX500SSD1 | 500 GB | SSD | userstore | 38 °C |
| sdc | Patriot P210 256GB | 256 GB | SSD | boot-pool | 39 °C |
| sde | Patriot P210 256GB | 256 GB | SSD | boot-pool | 37 °C |
| sdd, sdg, sdh, sdk, sdm, sdn | Seagate ST4000VN008 (IronWolf) | 4 TB | 5980 rpm | data | 36–40 °C |
| sdf, sdo, sdp | Seagate ST4000DM004 (Barracuda) | 4 TB | 5400 rpm | data | 40–45 °C |
| sdl | WD WD40EFRX (Red) | 4 TB | 5400 rpm | data | 41 °C |
| sdi | WD WD30EZRX (Green) | 3 TB | 5400 rpm | backups | 40 °C |
| sdj | TPH01203000GB | 3 TB | 7200 rpm | backups | 42 °C |
| sdq, sdr | WD WD10EARX / WD10EADS | 1 TB | — | backups | 33–34 °C |
| sds, sdt | WD WD20EARX | 2 TB | — | backups | 32–34 °C |

### Pools

| Pool | Layout | Raw size | Allocated | Notes |
|------|--------|----------|-----------|-------|
| `data` | 3× RAIDZ1 vdevs of 3 disks + 1 hot spare | 36.0 TB | 23.4 TB | The NFS workhorse — Prometheus, Grafana, Loki, media |
| `backups` | 3× 2-way mirrors | 6.0 TB | 0.06 TB | Mixed 1/2/3 TB pairs |
| `userstore` | 1× 2-way mirror (SSD) | 0.49 TB | 0.15 TB | |
| `boot-pool` | 1× 2-way mirror (SSD) | 253 GB | — | TrueNAS system |

All pools ONLINE. Note `data` is RAIDZ1 on 4 TB drives — a second failure during a resilver
loses the vdev, and resilver windows on 4 TB spinning disks are long.

## Expansion slots

Seven PCIe 3.0 slots, four occupied. **Three are free, all on CPU1.**

| Slot | Width / length | Occupant |
|------|----------------|----------|
| CPU1 SLOT1 | x8, short | **free** |
| CPU1 SLOT2 | x8, full length | **free** |
| CPU1 SLOT3 | x8, short | **free** |
| CPU2 SLOT4 | x16, full length | NVIDIA GK104 GeForce GTX 660 Ti (+ HDMI audio) |
| CPU2 SLOT5 | x8, short | LSI SAS3008 HBA |
| CPU2 SLOT6 | x8, full length | LSI SAS3008 HBA |
| CPU2 SLOT7 | x8, full length | LSI SAS3008 HBA |

X10DRH-iT has **no onboard M.2**, so any NVMe goes in one of the free CPU1 slots on an adapter:

- Single-drive M.2→PCIe x4 adapter: works in any of the three, no bifurcation needed, runs at
  PCIe 3.0 x4 (~3.5 GB/s).
- Multi-drive carrier: needs BIOS bifurcation (unconfirmed on this board at BIOS 3.4a) or an
  onboard PLX switch. Buy a switched card, or test bifurcation first.
- The GTX 660 Ti in SLOT4 is a Kepler card doing nothing that a NAS needs. Pulling it frees a
  x16 slot, drops idle power and heat, and is the tidiest way to make room on the CPU2 side
  where the HBAs live.
- Booting from NVMe on this BIOS generation is unreliable; the boot pool is already a mirrored
  SSD pair, so use new NVMe for ARC/`special`/SLOG duty instead. A SLOG in particular needs
  power-loss protection — consumer NVMe does not have it, so use an enterprise drive
  (Optane, or a PLP-equipped datacentre part) if that is the goal.

## Network

| Interface | Hardware | Link |
|-----------|----------|------|
| eno1 | Intel X540-AT2 port 0, onboard | 10GBase-T, up |
| enp3s0f1 | Intel X540-AT2 port 1, onboard | 10GBase-T, up |
| bond0 | LACP aggregate of both | up, 10.1.2.10/24, MTU 9000 |

Both onboard 10G ports are in an LACP LAG with jumbo frames. There is no spare onboard NIC port
— extra links would need a card in one of the free CPU1 slots.

## Needs a physical check

- PSU configuration: the chassis is a redundant-PSU platform but SMBIOS reports one power cord.
- Which bays are populated and which are empty, and the breakout cabling from each HBA.
- Whether the rear 12-bay cage is fitted and cabled.
- Whether the GTX 660 Ti can be removed (nothing in software depends on it).
- BMC credentials — the IPMI LAN at 10.1.2.9 is configured but no login is recorded in Bitwarden.
