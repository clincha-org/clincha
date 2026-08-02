#!/bin/bash
# Hardware inventory dump for the spec sheets in this directory.
# Run as root on a Proxmox host:  ssh root@10.1.2.11 'bash -s' < collect-hardware.sh > hawk01.txt
# hawkstore has no shell access — see README.md for the TrueNAS API equivalent.

set -u

section() { echo; echo "##### $1"; }

section HOSTNAME; hostname
section OS; cat /etc/os-release | head -3
section PVE; pveversion 2>/dev/null
section SYSTEM; dmidecode -t system
section BASEBOARD; dmidecode -t baseboard
section CHASSIS; dmidecode -t chassis
section BIOS; dmidecode -t bios
section CPU; dmidecode -t processor
section LSCPU; lscpu
section MEMARRAY; dmidecode -t 16
section DIMMS; dmidecode -t 17
section SLOTS; dmidecode -t slot
section PORTS; dmidecode -t 8
section MEMINFO; free -h
section BLOCK; lsblk -d -o NAME,SIZE,MODEL,SERIAL,ROTA,TRAN,REV
section LSBLK_TREE; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,TYPE

section SATA_PORTS
for d in /sys/block/sd*; do
    echo "$(basename "$d"): $(readlink -f "$d" | grep -o 'ata[0-9]*' | head -1) $(cat "$d/device/model" 2>/dev/null)"
done

section SMART
for d in $(lsblk -dn -o NAME | grep -E '^(sd|nvme)'); do
    echo "-- /dev/$d"
    smartctl -i "/dev/$d" | grep -Ei 'model|serial|capacity|form factor|rotation|sata version|firmware'
    smartctl -A "/dev/$d" | grep -Ei 'power_on_hours|percentage used|wear|total_lbas_written|data units written'
done

section LSPCI; lspci -nn
section PCIE_LINKS
for d in $(lspci -n | awk '{print $1}'); do
    lspci -vv -s "$d" | grep -qE 'LnkSta:' || continue
    echo "-- $d $(lspci -s "$d" | cut -d: -f3-)"
    lspci -vv -s "$d" | grep -E 'LnkCap:|LnkSta:'
done

section NET; ip -br link
for i in $(ls /sys/class/net | grep -Ev 'lo|tap|veth|fw|bonding_masters'); do
    echo "-- $i"
    ethtool "$i" 2>/dev/null | grep -Ei 'speed|duplex|supported link modes'
    ethtool -i "$i" 2>/dev/null | grep -Ei 'driver|bus-info'
done
section INTERFACES; cat /etc/network/interfaces

section ZPOOL; zpool list; zpool status
section LVM; pvs; vgs; lvs
section PVE_STORAGE_CFG; cat /etc/pve/storage.cfg
section GUESTS; qm list; pct list
section GUEST_CONF
for c in /etc/pve/qemu-server/*.conf /etc/pve/lxc/*.conf; do
    [ -f "$c" ] || continue
    echo "-- $c"
    grep -E '^(name|cores|memory|sockets|net[0-9]|scsi[0-9]|virtio[0-9]|rootfs|onboot|hostpci)' "$c"
done

section BOOTMODE; [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
section SECUREBOOT; mokutil --sb-state 2>/dev/null || echo n/a
section DRI; ls /dev/dri 2>/dev/null || echo none
