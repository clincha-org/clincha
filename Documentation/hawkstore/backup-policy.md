# hawkstore backup policy

What is protected on the NAS, what deliberately is not, and why.

hawkstore is **not managed as code** — snapshot tasks, replication tasks and cron jobs are
configured through the TrueNAS UI/API. This page is the record; there is no manifest that
captures it. If you change the tasks on the box, change this page in the same sitting.

Written **2026-08-05** (clincha-org/clincha#406), replacing the ad-hoc set of three tasks that
had grown up by accident.

## Tiers

Every dataset on `data` and `userstore` is in exactly one tier.

- **Protected** — periodic snapshot on the source, replicated to the `backups` pool.
- **Deliberately unprotected** — no snapshot, no replication, by decision. Listed below with
  the reason, so that "no backup" is never an accident nobody noticed.

There is no snapshot-only tier. If something is worth snapshotting it is small enough to
replicate, with the single exception of `data/media` — see below.

## Protected

| dataset | size | schedule (Europe/London) | replication target |
|---|---|---|---|
| `data/immich` | 137 GB | daily 23:00 | `backups/immich` |
| `userstore/userhome` | 103 GB | daily 23:30 | `backups/userhome` |
| `data/plex` | 45 GB | daily 00:00 | `backups/plex` |
| `data/factorio` | 1.6 GB | 6-hourly | `backups/factorio` |
| `data/prometheus` | 3.3 GB | daily 22:15 | `backups/telemetry/prometheus` |
| `data/loki` | small | daily 22:15 | `backups/telemetry/loki` |
| `userstore/s3` | 2.4 GB | daily 22:00 | `backups/s3` |
| `userstore/scans` | small | daily 22:00 | `backups/scans` |
| `data/grafana` | 60 MB | daily 22:30 | `backups/apps/grafana` |
| `data/sonarr` | 100 MB | daily 22:30 | `backups/apps/sonarr` |
| `data/radarr` | 780 MB | daily 22:30 | `backups/apps/radarr` |
| `data/bazarr` | small | daily 22:30 | `backups/apps/bazarr` |
| `data/sabnzbd` | small | daily 22:30 | `backups/apps/sabnzbd` |
| `data/tautulli` | small | daily 22:30 | `backups/apps/tautulli` |
| `data/tdarr` | 700 MB | daily 22:30 | `backups/apps/tdarr` |
| `data/ombi` | small | daily 22:30 | `backups/apps/ombi` |
| `data/uptime-kuma` | small | daily 22:30 | `backups/apps/uptime-kuma` |
| `data/family-archive` | 112 GB | daily 22:45 | `backups/family-archive` |
| `userstore/ix-apps/app_mounts/mariadb/data` | small | daily 22:45 (cron) | `backups/apps/mariadb` |

The two that actually matter are **Immich** (the family photo library — irreplaceable, and the
only copy) and **userhome**. `userstore/s3` is small but holds the terraform state and the
cluster kubeconfigs. `data/grafana` is only 60 MB but is every dashboard ever built here.

`data/family-archive` was pulled off Backblaze B2 on 2026-08-06 (#420) and the source buckets
`clinch-family-files` / `clinch-family-media` deleted, so this pool is now its only on-site
copy — treat it with the same care as Immich. It holds `files/aclinch/{Pictures,Phone Backup}`,
`files/cclinch/Documents` and the whole of the old `clinch-family-media` bucket: 28,039 files,
104 GiB, SHA1-verified against B2 before the buckets were removed.

Parts of `clinch-family-files` were **deliberately not kept** — `aclinch/Ammerdown` (54.9 GB),
`aclinch/Documents` (11.4 GB), `aclinch/Kieran`, `aclinch/TOR`, and nine orphaned
`duplicati-*.zip` chunks with no accompanying dlist. That was a decision, not an oversight.
`_manifest/` in the dataset holds the path, size, modtime and SHA1 of every object in both
buckets as they stood immediately before deletion, so what was discarded is at least on record.
Note that `cclinch/Documents` was kept while `aclinch/Documents` was not.

`userstore/ix-apps/app_mounts/mariadb/data` is the MariaDB behind uptime-kuma. Its monitor
definitions come from terraform, but the monitoring *history* only exists here.

### Schedules

Everything lands in a 22:00–23:30 band. Two windows are avoided deliberately:

- **02:00–07:00** — the nightly Plex Butler / NAS load window.
- **00:00** — where the pre-existing Plex and Factorio jobs already sit.

Cadence is daily for everything except Factorio, which stays 6-hourly because game saves churn
and a lost afternoon is a real loss. App configs change slowly; a day of granularity is plenty.

### Retention

Consistent across every task:

- **Source snapshots: 2 weeks.** Enough to undo a mistake you noticed, without pinning space on
  the pools that are actually filling up.
- **Replicated copies: 6 months.** The copy on `backups` outlives its source snapshot on
  purpose — that is the whole point of a backup, and it covers slow-burn corruption (an Immich
  or Grafana database going bad quietly) that a two-week window would miss.

`backups` is a 5.44 TB pool holding ~50 GB before this change, so a 6-month tail on ~250 GB of
new coverage is not a space concern. Revisit if the pool passes ~50%.

## Deliberately unprotected

| dataset | size | why |
|---|---|---|
| `data/media` | 14.4 TB | Re-acquirable. Would not fit on a 5.44 TB `backups` pool in any case. Snapshot-only was considered and rejected — the point of a snapshot here would be to survive an accidental mass delete, and the media library is exactly the thing we are willing to re-acquire. |
| `data/satisfactory` | 0 bytes | Stale, no workload. Slated for removal in #408. |
| `data/backups/longhorn` | 25.9 GB | Longhorn was decommissioned 2026-07-27. Its snapshot and replication tasks were retired as part of #406; the datasets and their existing snapshots are left in place pending #408. |

## Off-box copy

Every *ZFS replication* is still `LOCAL` `PUSH`, `data`/`userstore` → `backups`, all three pools
in the same chassis. That protects against accidental deletion, app-level corruption and a single
pool failing, but not against losing the box.

Since **2026-08-06** (#420) the four datasets with no other copy are also pushed to Backblaze B2,
encrypted client-side:

| dataset | remote directory |
|---|---|
| `data/immich` | `offsite:immich` |
| `userstore/userhome` | `offsite:userhome` |
| `userstore/s3` | `offsite:s3` |
| `data/family-archive` | `offsite:family-archive` |

`systemd` unit `offsite-backup.service`, timer daily at **09:00** with a 15-minute jitter — clear
of both the 02:00–07:00 NAS load window and the 22:00–23:30 replication band. Script at
`/root/offsite-backup.sh`, logs in `/root/offsite-backup-logs/` (pruned at 30 days).

The job snapshots each dataset as `@offsite-<timestamp>`, syncs from
`.zfs/snapshot/<tag>/`, then destroys the snapshot. Syncing the snapshot rather than the live
mount is what makes the upload a consistent point-in-time; a stale `@offsite-*` snapshot means a
previous run was killed mid-flight, and the next run clears it.

### What B2 sees

Nothing readable. The remote is an `rclone crypt` wrapping
`b2backup:clincha-hawkstore-offsite`, so **file contents and filenames are both encrypted**
before leaving the house. In the raw bucket a photo looks like
`rmoa87bl476m7njs1ponpjdeek/56ga422gc8kie1h6mvgtprfk44`. SSE-B2 is enabled underneath as well,
but that protects nothing we are not already protecting ourselves.

**The two crypt values exist only in Bitwarden**, item `Backblaze - hawkstore offsite backup`
(`crypt password` and `crypt password2`). This is the whole point: a key stored on hawkstore
would be worthless in exactly the scenario the off-box copy is for. If that vault item is lost,
the bucket is unrecoverable ciphertext — there is no recovery path and no support ticket that
fixes it.

### The application key is deliberately weak

The key the NAS holds is scoped to the one bucket and carries only
`listBuckets, listFiles, readFiles, writeFiles`. It has **no `deleteFiles`**, so a compromised
or misbehaving hawkstore can hide objects but never hard-delete them, and the bucket lifecycle
rule keeps hidden versions for **30 days**. Verified by trying: a hard-delete against the bucket
with this key returns `401 unauthorized` and the object survives.

Admin operations that genuinely need to destroy things use the account-wide `backblaze` vault
item instead, which the NAS does not have.

### Restoring

The restore path deliberately does not involve hawkstore. From any machine with `rclone`, using
only the Bitwarden item:

```sh
rclone config create b2raw b2 account <keyID> key <applicationKey>
rclone config create arch crypt remote b2raw:clincha-hawkstore-offsite \
    password  "$(rclone obscure '<crypt password>')" \
    password2 "$(rclone obscure '<crypt password2>')"
rclone ls arch:
```

This was exercised end-to-end on 2026-08-06 from a machine that is not hawkstore, rebuilding the
config from the vault alone. Re-test it whenever the credential changes — an untested off-box
backup is a belief, not a backup.

### Cost

~355 GB at B2's $6/TB/month is roughly **$2.15/month**. Egress is free up to 3× stored data per
month, so a full restore of this set costs nothing; a repeated one would.

## The ix-apps exception

TrueNAS hides `ix-apps` datasets from the periodic-snapshot-task API — `pool.snapshottask`
answers `Dataset not found` for `userstore/ix-apps/...`, and so does `pool.dataset.query`, even
though `zfs` itself is perfectly happy to snapshot it and `pool.snapshot` both creates and lists
snapshots on it normally.

So the MariaDB dataset is snapshotted by a **cron job** (`root`, daily 22:45) rather than a
periodic task:

```sh
/usr/sbin/zfs snapshot userstore/ix-apps/app_mounts/mariadb/data@auto-$(date +\%Y-\%m-\%d_\%H-\%M); \
/usr/sbin/zfs list -H -o name -t snapshot -s creation -d 1 userstore/ix-apps/app_mounts/mariadb/data \
  | grep @auto- | head -n -14 | xargs -r -n1 /usr/sbin/zfs destroy
```

The `\%` escaping is required — cron treats a bare `%` as a newline. Retention is by count
(keep the newest 14) rather than by age, which at a daily cadence is the same two weeks as
everywhere else and needs no date arithmetic.

Its replication task cannot bind to a periodic task, so it uses `also_include_naming_schema`
with the same `auto-%Y-%m-%d_%H-%M` schema and its own schedule.

## Verifying

```sh
# every snapshot task and when it last ran
midclt call pool.snapshottask.query | jq -r '.[] | "\(.id) \(.dataset)"'

# every replication task and its last state — all should read FINISHED
midclt call replication.query | jq -r '.[] | "\(.name) \(.state.state)"'

# what actually landed on the backups pool
zfs list -r backups
```

A replication that has never run reads `PENDING`, not `FINISHED`. A task whose source dataset
has no snapshot yet will sit in `WAITING`.
