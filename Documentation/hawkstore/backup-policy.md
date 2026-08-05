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
| `userstore/ix-apps/app_mounts/mariadb/data` | small | daily 22:45 (cron) | `backups/apps/mariadb` |

The two that actually matter are **Immich** (the family photo library — irreplaceable, and the
only copy) and **userhome**. `userstore/s3` is small but holds the terraform state and the
cluster kubeconfigs. `data/grafana` is only 60 MB but is every dashboard ever built here.

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

## The off-box gap

**Every replication is `LOCAL` `PUSH`, `data`/`userstore` → `backups`, all three pools in the
same chassis.** That protects against accidental deletion, app-level corruption and a single
pool failing. It does **not** protect against losing the box — fire, theft, a PSU taking the
backplane with it, or a filesystem-level catastrophe.

This is a **known, accepted gap**, not an oversight. Off-box replication for Immich and
userhome was considered as part of #406 and deliberately deferred: it needs a provider
decision, a credential and an ongoing cost, none of which should hold up closing the
zero-coverage problem. Tracked separately.

If you only ever fix one thing on this page, make it this one — 137 GB of family photos exist
in exactly one building.

## The ix-apps exception

TrueNAS hides `ix-apps` datasets from the periodic-snapshot-task API — `pool.snapshottask`
answers `Dataset not found` for `userstore/ix-apps/...`, even though `zfs` itself is perfectly
happy to snapshot it and `pool.snapshot` creates one on request. They are also filtered out of
`pool.snapshot` list queries, though a direct lookup by id works.

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
