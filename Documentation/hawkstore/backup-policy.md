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
definitions come from terraform, but the monitoring *history* only exists here. What every app
on the box is for is in [apps.md](apps.md).

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

`data/satisfactory` and the two `longhorn` datasets were listed here until 2026-08-05. All three
were deleted under #408 along with `data/backups`, so there is nothing left to leave unprotected.

## Kept on purpose

Two things on the box look stale by every automatic measure and are kept anyway. Both were put to
Angus under #408 on 2026-08-07 and both answers were *keep* — treat them as settled rather than
re-raising them at the next audit.

**Old Factorio save directories.** The live deployment mounts only `/mnt/data/factorio/2026`.
Alongside it sit `saves`, `spaceage`, `runsmart`, `speedrun`, `proposal` and `config` — 872 MB
across worlds last touched between May 2025 and October 2025. Every file except `saves/space.zip`
is an `_autosaveN.zip`, so for each of those worlds the autosaves are the only copy there is.
That is 0.002% of a 36 TB pool against a set of game states that cannot be regenerated, and
`proposal` has sentimental value on top. They ride along in the existing `data/factorio`
6-hourly snapshot.

**`userstore/scans`.** Empty, mtime 2025-09-27, backed by an enabled SMB share and written to by
the `hawkprint` account (uid 3002, *clinch-printer*), whose password was set the same day. It is a
scanner dropbox: **empty is its normal resting state**, so an old mtime and a zero byte count are
not evidence that anything is unused. The scanner is still in service. Its daily snapshot and
replication to `backups/scans` stay.

## Off-box copy

Every *ZFS replication* is still `LOCAL` `PUSH`, `data`/`userstore` → `backups`, all three pools
in the same chassis. That protects against accidental deletion, app-level corruption and a single
pool failing, but not against losing the box.

Since **2026-08-06** (#420) the four datasets with no other copy are also pushed to Backblaze B2,
encrypted client-side, by **native TrueNAS cloud sync tasks**. They appear under Data
Protection, keep their own job history, and raise a `CloudSyncTaskFailed` alert when they fail.
Credential `Backblaze B2 - hawkstore offsite` (id 1).

| task | dataset | bucket folder | schedule |
|---|---|---|---|
| 1 | `data/family-archive` | `family-archive` | daily 09:00 |
| 2 | `data/immich` | `immich` | daily 09:15 |
| 3 | `userstore/userhome` | `userhome` | daily 09:30 |
| 4 | `userstore/s3` | `s3` | daily 09:45 |

All four are `PUSH` / `SYNC` with `snapshot: true`, which makes TrueNAS take a temporary ZFS
snapshot and upload from that rather than the live mount — so each run is a consistent
point-in-time. The 09:00 band is clear of both the 02:00–07:00 NAS load window and the
22:00–23:30 replication band.

An earlier iteration of this used a `systemd` timer running a hand-rolled `rclone` script. It
was replaced on 2026-08-07 because a script has no failure alerting (it could fail nightly and
silently for months), no job history, and lived in `/root` on the boot environment, which is
not a supported home for user files and is outside the TrueNAS config backup.

### What B2 sees

The four **folder names are plaintext** — `family-archive`, `immich`, `s3`, `userhome`.
Everything beneath them is encrypted: **file contents and every path segment**. In the raw
bucket a photo looks like `immich/56ga422gc8kie1h6mvgtprfk44/2p9ktc1r4vhmv0k8h1qbo6qc7g`.
SSE-B2 is enabled underneath as well, but that protects nothing we are not already protecting
ourselves.

The plaintext folder level is a consequence of how cloud sync tasks work: `folder` is applied
to the raw bucket and encryption is rooted *below* it. Leaking four dataset names is a fair
price for staying on the supported path. Do not try to "fix" it by pointing a task at an
encrypted directory name — see the trap below.

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
# crypt is rooted at the FOLDER, not the bucket — one remote per dataset
rclone config create immich crypt remote b2raw:clincha-hawkstore-offsite/immich \
    password  "$(rclone obscure '<crypt password>')" \
    password2 "$(rclone obscure '<crypt password2>')"
rclone ls immich:
```

Swap `immich` for `family-archive`, `userhome` or `s3` as needed. All four share the same
password and salt, so only the remote path changes.

This was exercised end-to-end on 2026-08-06 from a machine that is not hawkstore, rebuilding the
config from the vault alone. Re-test it whenever the credential changes — an untested off-box
backup is a belief, not a backup.

### Trap: `folder` sits above the encryption boundary

TrueNAS derives the crypt key exactly as `rclone` does, so a cloud sync task with the same
password and salt *can* read data written by a bare `rclone crypt` remote — `cloudsync.list_directory`
will happily return a `Decrypted` name for each entry. That is not sufficient for a task to
adopt existing data, because `folder` is applied to the **raw** bucket and encryption is rooted
below it. A crypt remote rooted at the bucket writes `enc(immich)/enc(...)`; a task with
`folder: immich` writes `immich/enc(...)`. Same key, different tree.

Pointing a task at the encrypted directory name does make it adopt the old tree with no
re-upload, and it was tested working — but it leaves an opaque string in the task config that
anyone editing the task in the UI would naturally "correct" to the decrypted name, silently
starting a fresh 355 GB upload. The plaintext-folder layout was chosen instead.

Note also that the **v2.0 REST endpoint silently drops the encryption fields** on
`cloudsync/list_directory` — it returns raw encrypted names as if no password were supplied.
Only `midclt call cloudsync.list_directory` honours them. Do not conclude from a REST response
that decryption is broken.

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
