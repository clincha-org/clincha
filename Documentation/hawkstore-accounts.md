# hawkstore users and groups

hawkstore (`10.1.2.10`) is **not managed as code** — users, groups and datasets are configured
through the TrueNAS UI/API. Only the Kubernetes consumers live in this repo, so any change here
has a manual NAS half that must land in the same window.

## The rule

**GID == UID for every account with its own primary group.** The one deliberate exception is the
media stack, where nine app accounts share `media(3011)`.

Before creating an account, check **both** `user.query` and `group.query`. Never take "the next
free number" from one sequence alone. Until 2026-08-05 the two sequences had drifted apart and
almost every GID in 3003–3022 was also a *different* account's UID; that is how Ombi shipped with
`PUID: 3015`, which was `asta` — a real person with SMB access.

## Current map

| account | uid | primary group | gid | notes |
|---|---|---|---|---|
| clincha | 3000 | clincha | 3000 | human, SMB |
| cclinch | 3001 | cclinch | 3001 | human, SMB |
| hawkprint | 3002 | hawkprint | 3002 | printer/scanner, SMB |
| prometheus | 3003 | prometheus | 3003 | `/mnt/userstore/prometheus` |
| ansible | 3004 | ansible | 3004 | |
| grafana | 3005 | grafana | 3005 | `/mnt/userstore/grafana` |
| dave | 3006 | dave | 3006 | FULL_ADMIN, owns the API key |
| nasexporter | 3007 | nasexporter | 3007 | bound to privilege `nas-exporter-readonly` |
| tautulli | 3008 | media | 3011 | |
| tdarr | 3009 | media | 3011 | |
| plex | 3010 | media | 3011 | |
| sonarr | 3011 | media | 3011 | |
| radarr | 3012 | media | 3011 | |
| bazarr | 3013 | media | 3011 | |
| sabnzbd | 3014 | media | 3011 | |
| asta | 3015 | asta | 3015 | human, SMB — treat as fixed |
| immich | 3016 | media | 3011 | |
| ombi | 3017 | media | 3011 | |
| loki | 3018 | loki | 3018 | `/mnt/userstore/loki` |
| uptimekuma | 3019 | uptimekuma | 3019 | `/mnt/userstore/uptime-kuma` |
| s3 | 3020 | s3 | 3020 | rustfs, `/mnt/userstore/s3` |

Shared/auxiliary groups: `media(3011)`, `printing(3023)` (clincha, hawkprint — owns
`/mnt/userstore/scans`), `family(3024)` (clincha, cclinch, asta).

Free GIDs: 3008–3010, 3012–3014, 3016, 3017, 3021, 3022, 3025+.

## Renumbering, if it is ever needed again

TrueNAS will **not** change a GID. `group.update` rejects the field outright, so a renumber is
delete + recreate at the target GID, with the user's primary group repointed in between:

1. rename the old group out of the way
2. create the new group at the target GID (it must be free *at that moment*)
3. `user.update` the owner's primary group to the new group
4. delete the old group
5. `chgrp` the affected trees

Because step 2 needs a free target, a renumber is a strict cascade — moving `prometheus` onto
3003 first required `printing` to vacate it. Order the moves so each target frees up before it is
needed, and stop any workload holding files under a group before renumbering it.

Two traps found doing this on 2026-08-05:

- **Admin accounts are frozen while global 2FA is on.** Any `user.update` on an account holding
  `FULL_ADMIN` without its own 2FA configured returns HTTP 422. This affects `dave`.
- **A group can be pinned by a privilege.** Deleting `nasexporter`'s old group failed until
  privilege `nas-exporter-readonly` was repointed to the new GID. Check `privilege.query` for the
  GID before deleting, or the account silently loses its roles.

Also note that a TrueNAS *app* carries its own `run_as` uid/gid, independent of the dataset: after
the realignment `rustfs` kept writing as the deleted GID 3022 until `app.update` set it to 3020.

## NFS and SMB

Exports are `root_squash` with empty maproot/mapall, so pods set `runAsUser`/`runAsGroup` rather
than relying on root. Server-side group membership does not gate NFS access — under AUTH_SYS the
*client* supplies the GID — so a wrong `runAsGroup` fails silently rather than loudly. It matters
for SMB, local tools, and if `manage_gids` is ever enabled.
