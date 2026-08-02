# Hardware spec sheets

Physical machine inventory for the homelab. One page per box, covering board, CPU, memory,
storage, expansion slots and what is free — enough to answer "will this upgrade fit?" without
opening the case.

Captured **2026-08-01** from the live machines (see [Collection method](#collection-method)).
Anything that firmware cannot report — PSU model, case model, cooler, fan and cable inventory —
is listed per page under "Needs a physical check".

## The machines

| Host | Site | Role | Hardware | CPU | RAM | Network |
|------|------|------|----------|-----|-----|---------|
| [hawkstore](hawkstore.md) | Hawkfield | TrueNAS storage | Supermicro SSG-6048R-E1CR36L (X10DRH-iT) | 2× Xeon E5-2667 v4 (16c/32t) | 128 GiB DDR4 ECC RDIMM | 2× 10GBase-T bonded |
| [hawk01](hawk01.md) | Hawkfield | Proxmox, k8s-hawk-1 + dns-hawk-1 | ASUS PRIME B450M-A II | Ryzen 5 5600GT (6c/12t) | 80 GiB DDR4 non-ECC | 1GbE + 10G SFP+ |
| [hawk02](hawk02.md) | Hawkfield | Proxmox, k8s-hawk-2 + claude-hawk-1 | ASUS PRIME B450M-A II | Ryzen 5 5600GT (6c/12t) | 80 GiB DDR4 non-ECC | 1GbE + 10G SFP+ |
| [hawk03](hawk03.md) | Hawkfield | Proxmox, k8s-hawk-3 | ASUS PRIME B450M-A II | Ryzen 5 5600GT (6c/12t) | 80 GiB DDR4 non-ECC | 1GbE + 10G SFP+ |
| [lon01](lon01.md) | London | Proxmox, k8s-lon-1 + dns-lon-1 | HP EliteDesk 705 G4 DM 65W | Ryzen 5 PRO 2400G (4c/8t) | 16 GiB DDR4 SODIMM | 1GbE |

Not covered: `clincha-main` (Angus's desktop, not part of the cluster) and network kit (UniFi
gateway, switches). The k8s nodes, DNS resolvers and `claude-hawk-1` are guests — see the host
page of the machine they run on.

## Expansion at a glance

| Host | Free DIMM slots | Free drive attach points | Free PCIe slots |
|------|-----------------|--------------------------|-----------------|
| hawkstore | 8 of 16 (4 per CPU) | 3 free SAS3008 ports + spare drive bays | 3× PCIe 3.0 x8 (all on CPU1) |
| hawk01 | 0 of 4 | 4 of 6 SATA; M.2 occupied | 1× PCIe 2.0 x1 |
| hawk02 | 0 of 4 | 5 of 6 SATA; M.2 occupied | 1× PCIe 2.0 x1 |
| hawk03 | 0 of 4 | 4 of 6 SATA; M.2 occupied | 1× PCIe 2.0 x1 |
| lon01 | 0 of 2 | 0 (1 SATA + 1 M.2, both used) | M.2 WLAN slot only |

## Worked examples

### Can I add an NVMe drive to hawkstore?

Yes. X10DRH-iT has no onboard M.2, so it goes in a PCIe slot, and three are free:
**CPU1 SLOT1** (x8, short), **CPU1 SLOT2** (x8, full length) and **CPU1 SLOT3** (x8, short).
All three hang off CPU1, which is populated, so they are electrically live.

- A single-drive M.2→PCIe x4 adapter needs no bifurcation and works in any of the three.
- A multi-drive carrier (2 or 4 M.2 on one card) needs either PCIe bifurcation in BIOS or an
  onboard PLX switch. Bifurcation support on X10DRH-iT BIOS 3.4a is unconfirmed — buy a
  switched card, or test bifurcation before committing.
- Drives run at PCIe 3.0 x4 max (~3.5 GB/s), fine for any consumer NVMe.
- Booting from it is a separate question: the boot pool is already a mirror of two SATA SSDs,
  and NVMe boot support on this BIOS generation is patchy. Adding it as an L2ARC, `special`
  vdev or SLOG for the `data` pool is the low-risk use — but a SLOG needs power-loss protection,
  which consumer NVMe does not have.
- NUMA note: the HBAs are all on CPU2, so an NVMe on CPU1 crosses QPI for pool traffic. Not
  material at these speeds, but it is why SLOT4-7 would have been the tidier choice if free.

Full detail: [hawkstore.md](hawkstore.md).

### How would I swap the motherboards in the hawkfield cluster?

All three hawk nodes are identical: ASUS PRIME B450M-A II, micro-ATX, socket AM4, running a
Ryzen 5 5600GT with 4× DDR4 UDIMM slots full. A replacement board must therefore be:

- **micro-ATX or smaller** to fit the existing (unidentified — check physically) desktop cases.
- **Socket AM4** to keep the 5600GT, with a BIOS that supports Cezanne (Ryzen 5000G). Any
  B550/X570 board ships new enough firmware; a second-hand B450 may need a BIOS update first.
- **4× DDR4 DIMM slots** to carry over all 80 GiB, which is 2× 8 GiB + 2× 32 GiB of mismatched
  Corsair kits currently clocked down to 2133 MT/s. A board swap is the natural moment to
  replace those with a matched 2× 32 GiB kit and get the memory running at rated speed.
- **1× PCIe x8-or-wider slot** for the Intel X520 10G NIC (currently in the x16 slot at Gen2 x8),
  plus ideally a second slot for the GT 730 — though the 5600GT has working integrated graphics,
  so the GT 730 can simply be dropped. Note the DMI slot labels on these boards are unreliable:
  the GT 730 is actually negotiating x1 Gen1, so it is in a x1 slot, not the x16.
- **1× M.2 PCIe 3.0 x4** for the boot NVMe, and **2+ SATA** ports for the ZFS `fast` mirror.

Moving to B550 would upgrade the M.2 to Gen4 and the x16 slot to Gen4 — neither matters for a
Gen3 boot drive and a Gen2 NIC. The real reasons to swap would be ECC support (the current
boards run non-ECC, so a Ryzen PRO or Athlon PRO plus an ECC-capable board would be the play) or
IPMI, which none of these consumer boards have.

Procedure notes: Proxmox survives a board swap as long as the disks move with it, but the NIC
names change (`enp1s0f0`, `enp8s0`) and `/etc/network/interfaces` pins those names to `vmbr0`
and `vmbr1` — fix that before rebooting or the node comes up unreachable. Take one node at a
time; the k8s control plane needs 2 of 3 up for etcd quorum. Physical access on these boxes is
documented in [../server-refresh/physical-access.md](../server-refresh/physical-access.md).

Full detail: [hawk01.md](hawk01.md), [hawk02.md](hawk02.md), [hawk03.md](hawk03.md).

## Collection method

The Proxmox hosts were captured over SSH as root with
[`collect-hardware.sh`](collect-hardware.sh):

```bash
ssh root@10.1.2.11 'bash -s' < Documentation/hardware/collect-hardware.sh > hawk01.txt
```

hawkstore has no SSH access enabled, so it was captured through the TrueNAS API instead
(`wss://10.1.2.10/api/current`, API key `Hawkstore API key` in Bitwarden):
`system.info`, `disk.details`, `pool.query`, `interface.query`, `ipmi.lan.query` and
`virt.device.pci_choices` for the PCI inventory. DIMM and PCIe slot detail is not exposed by any
API method, so the raw SMBIOS tables were pulled with `core.download` on `filesystem.get`
(`/sys/firmware/dmi/tables/DMI` and `smbios_entry_point`), reassembled into a dmidecode dump and
decoded locally:

```python
ep = bytearray(open("smbios_entry_point", "rb").read()).ljust(0x1f, b"\0")
tb = open("DMI", "rb").read()
struct.pack_into("<I", ep, 0x18, 0x20)          # dmidecode reads the table from offset 0x20
struct.pack_into("<H", ep, 0x16, len(tb))
# recompute the _DMI_ and _SM_ checksums, then concatenate ep.ljust(32) + tb
```

```bash
dmidecode --from-dump hawkstore-dmi.dump
```

Refresh these pages after any hardware change, and re-check the "Needs a physical check"
sections when a case is open anyway.
