# hawkstore apps

What each TrueNAS app on hawkstore (`10.1.2.10`) is for, named by its **consumer** rather than
by its software.

hawkstore is **not managed as code** — apps are installed and configured through the TrueNAS
UI/API, so this page is the only record of intent. TrueNAS catalog apps have **no editable
description or notes field**: `description` comes from the catalog and is read-only, so there is
nowhere on the box to write "this one backs uptime-kuma". If you add, remove or repurpose an app,
change this page in the same sitting or the knowledge is gone.

Written **2026-08-07** (clincha-org/clincha#407), after two database apps had sat running for
weeks with nothing recording what they served.

## Current apps

| app | version | serves | data | published port |
|---|---|---|---|---|
| `rustfs` | 1.0.0-beta.11 | Terraform remote state and cluster kubeconfigs. Object store for the whole homelab; replaced MinIO 2026-07-30. Managed by `terraform/rustfs`. | `/mnt/userstore/s3` | 30292, 30293 on `0.0.0.0` |
| `mariadb` | 11.8.8 | **uptime-kuma**, the status page at `status.clincha.co.uk`. Sole consumer. | `/mnt/.ix-apps/app_mounts/mariadb/data` (local ZFS) | 3306 on `10.1.2.10` |
| `tdarr-node` | 2.85.01 | Transcoding worker for the Tdarr server in the cluster. Reads the media library directly off the NAS rather than over the network. | `/mnt/data/media` (ro work), transcodes under `app_mounts/tdarr-node` | none |

### mariadb

Stood up 2026-08-02 (#404) to get uptime-kuma off SQLite. Its `/app/data` lived on an NFS mount
where fsync costs 58–105 ms against 7 ms locally, so a single WAL insert took ~558 ms, the
readiness and liveness probes both blew, and the pod restarted 228 times in 5 days.

The Kubernetes side is in this repo at
`kubernetes/flux/infrastructure/base/uptime-kuma/helm-release.yml` — `externalDatabase` pointing
at `10.1.2.10:3306`, database `uptime_kuma`, credentials from the
`uptime-kuma-mariadb-credentials` secret. Root and application passwords are in the Bitwarden
item **`Uptime Kuma MariaDB`**.

Deliberately on `.ix-apps` (local ZFS) and not on `data` — putting it on NFS would recreate the
exact problem it was installed to solve. It is snapshotted and replicated regardless; see
[backup-policy.md](backup-policy.md). Monitor *definitions* come from `terraform/uptime-kuma`, so
they are reproducible, but the monitoring **history** exists only here.

Port 3306 binds to `10.1.2.10` alone as of 2026-08-07. It was previously published on every
interface — `0.0.0.0` and `::`, which on this box means `docker0`, three compose bridges and
`incusbr0` as well as the LAN. The k8s nodes reach it over the LAN address, so nothing legitimate
used the others. Narrowing it drops existing connections: uptime-kuma logs
`Connection lost: The server closed the connection` and reconnects through its pool without
restarting the pod.

## Removed

### mongodb — removed 2026-08-07

Installed 2026-07-28, removed under #407 with Angus's confirmation. It served nothing.

Evidence, for the next person who wonders whether it was load-bearing: across the app's entire
lifetime the container log held **397,351 connections and every one came from `127.0.0.1`** — the
TrueNAS healthcheck's own `mongosh` probe, every 30 seconds. No client ever connected over the
network. Nothing in this repo, in `/source`, or in any Deployment, StatefulSet or ConfigMap in
the cluster referenced `27017`, `mongo` or a `mongodb://` URL.

It did hold data, which the first pass at #407 missed. One database `systems-system`, an empty
`systems` collection and a `habits` collection containing a single document,
`{ name: 'Recipe selection' }` — the start of a habit tracker, whose ObjectId dates it to
**2025-08-04**, a year before this container existed. Two things made it easy to miss: the app's
configured database name was `system-systems`, the reverse of the real one, and the 496 MB on
disk was almost entirely `diagnostic.data`, MongoDB's own FTDC metrics. Actual user data was
135 KB.

Both a `mongodump` archive and a tar of the data directory are at
`/mnt/backups/apps/mongodb-decommission-20260807/`, so the document is recoverable.

Its data lived at `/mnt/userstore/mongodb` — a bare directory on the `userstore` **root**
dataset, not a dataset of its own, so it could never have been snapshotted or replicated
independently. That directory is now deleted, which also closes item 6 of #408. Port 27017 is no
longer listening.
