# Runbook: host disk space

Covers `HostDiskUsageHigh` (warning, over 80% for 15m) and `HostDiskUsageCritical`
(critical, 95% or more for 5m), delivered to Telegram by Alertmanager.

Both read `node_filesystem_*` from the `integrations/unix` job, so they cover every host Alloy
reports for: the Proxmox hosts, k8s nodes, VMs, LXCs, the Pi and the workstation. NFS and
pseudo-filesystems are excluded, as is the workstation's `/mnt/games`.

The percentage is computed from available space, which excludes ext4's reserved blocks. It reads
a few points higher than `df`'s `Use%`.

## Why it matters beyond the host

A full root disk silently stops telemetry. On 2026-10-28 lon01's root filled and Alloy could no
longer write its positions file, so every scrape failed with `no space left on device`. The host
kept running and the Alloy service stayed `active`; the metrics just stopped arriving, and
nothing noticed for five days.

## Diagnose

```bash
df -h /
du -xh --max-depth=1 / | sort -rh | head
du -xh --max-depth=2 /usr/lib/modules /var/cache /var/log | sort -rh | head
```

## Usual culprits on Proxmox hosts

- **Old kernels.** Proxmox installs a new kernel on every update and never removes the old ones.
  Each costs roughly 1 GB across `/usr/lib/modules` and `/boot`. Keep the running kernel and the
  newest two or three, purge the rest, then `apt autoremove --purge`.
  ```bash
  dpkg -l 'proxmox-kernel-[0-9]*-pve-signed' | awk '/^ii/{print $2}'
  uname -r
  ```
- **apt cache.** `apt-get clean`.
- **ISOs and templates** in `/var/lib/vz/template`.
- **Journal.** `journalctl --vacuum-size=200M`.

After freeing space, `systemctl restart alloy` if metrics did not resume on their own.
