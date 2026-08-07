# Runbook: pod restart alerts

Covers `PodRestartingFrequently` (warning) and `PodCrashLooping` (critical), delivered to
Telegram by Alertmanager.

## The alerts

| Alert | Severity | Fires when |
| --- | --- | --- |
| `PodRestartingFrequently` | warning | a container restarted 3+ times in the last hour, sustained for 10m |
| `PodCrashLooping` | critical | a container has been in `CrashLoopBackOff` for 15m |

Both carry `namespace`, `pod` and `container` labels, and cover **every namespace** in the
cluster.

The warning window is one hour rather than fifteen minutes on purpose. Kubernetes caps
CrashLoopBackOff at a 5-minute backoff, so a 15-minute window can only ever hold about three
restarts — any threshold on it sits right on the boundary and flaps.

A crash-looping pod trips **both** alerts. There is no inhibition rule, so expect two messages
for the same incident. If that gets annoying, add an `inhibit_rules` block to
`kubernetes/flux/infrastructure/hawkfield/monitoring/alertmanager.yml` matching on
`namespace` + `pod`.

## How the alert reaches you

```
kubelet → kube-state-metrics → Alloy (scrape + remote_write) → Prometheus
       → alert rules → Alertmanager → Telegram (clincha_grafana_bot)
```

Nothing here goes through Grafana. Grafana's own alerting is unused — deliberately, since
Grafana is one of the things being watched.

- Rules: `kubernetes/flux/infrastructure/hawkfield/monitoring/alert-rules.yml`
- Routing: `kubernetes/flux/infrastructure/hawkfield/monitoring/alertmanager.yml`
- Bot token + chat ID: `alertmanager-telegram.sops.yaml` (SOPS, same PGP key as every other
  secret in this repo). The token is also stored in Bitwarden as `Alertmanager Telegram bot`.
- Alertmanager UI: <https://alertmanager.clinch-home.com> (LAN only)
- Prometheus alert state: <https://prometheus.clinch-home.com/alerts>

## Quiet hours — know the exact behaviour

Warnings are muted 23:00–06:00 Europe/London. Critical alerts are never muted.

Muting is **suppression, not queueing**. Alertmanager has no store-and-forward. So:

- A warning that is *still firing* when the window lifts is delivered shortly after 06:00.
  The warning route uses `repeat_interval: 4h` so the next delivery attempt lands within an
  hour or so of 06:00 rather than waiting on the 6h default.
- A warning that fires *and resolves* entirely inside the window is **never announced**. You
  will not hear about it at all.

That second case matters here: the nightly Plex Butler thumbnail run (02:00–07:00) drives NAS
load and is the most likely source of overnight restarts. If you want a morning record of what
happened overnight, check Prometheus rather than trusting silence.

Note the overlap: Butler runs until 07:00 but muting stops at 06:00, so Butler-driven restarts
between 06:00 and 07:00 *will* reach you. If that turns into a recurring morning nuisance, move
the mute back to 07:00 rather than widening the alert threshold.

## Triage

1. **Identify.** The message gives you `namespace/pod (container)`.

   ```bash
   kubectl -n <ns> get pods
   kubectl -n <ns> describe pod <pod> | tail -40
   ```

2. **Read the crash itself**, not the current attempt:

   ```bash
   kubectl -n <ns> logs <pod> --previous --tail=50
   ```

   `--previous` is the important part — the running container is usually a fresh attempt that
   has not failed yet.

3. **Check for the obvious causes**, in rough order of likelihood here:
   - `OOMKilled` in `describe` output → memory limit too low.
   - NFS unavailable → check hawkstore is up (`ssh dave@10.1.2.10`). Most stateful workloads
     here mount `10.1.2.10` directly and fail hard when it goes away.
   - A file lock held by another pod → see the worked example below.
   - A bad image tag from a Renovate bump → compare ReplicaSets (see below).

4. **Silence while you work**, so you are not re-alerted mid-fix:

   ```bash
   amtool --alertmanager.url=https://alertmanager.clinch-home.com \
     silence add alertname=PodCrashLooping namespace=<ns> pod=<pod> \
     --duration=2h --comment="fixing X"
   ```

   Or use the Alertmanager UI. Silences survive restarts — they are on NFS at
   `/mnt/data/alertmanager`.

## Worked example: Grafana, 2026-08-06

Symptom: `grafana-f7fc89fb5-vzzqs` in `CrashLoopBackOff`, 286 restarts over 24h — while Grafana
itself stayed up and served normally.

Cause: two Grafana pods existed. Renovate bumped `13.1.1 → 13.1.2`, and the Deployment used the
default `RollingUpdate` strategy. With `replicas: 1`, `maxSurge: 25%` rounds *up* to 1, so
Kubernetes started the new pod before removing the old one. Both mount the same NFS directory
`/mnt/data/grafana`, and Grafana's bleve unified-search index takes an exclusive lock:

```
level=error msg="index is locked by another process"
  indexDir=/var/lib/grafana/unified-search/bleve/... err=timeout
Error: ✗ index is locked by another process
```

The old pod held the lock, the new pod could not start, the rollout sat at
`ProgressDeadlineExceeded` for 24 hours, and the old pod kept serving — which is why nothing
looked broken from the outside.

Fix: `strategy: Recreate` on the Deployment. The same reasoning applies to Prometheus (TSDB lock
file) and Alertmanager (silences + nflog), so all three are set to `Recreate`.

**Generalise this:** any single-replica Deployment on shared NFS in this cluster needs
`Recreate`. `RollingUpdate` will overlap pods and whatever single-writer lock the app uses will
break the upgrade. Check for this first whenever a crash-loop appears immediately after a
version bump.

Useful when you suspect a stuck rollout:

```bash
kubectl -n <ns> get rs -l app.kubernetes.io/name=<app> \
  -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,DESIRED:.spec.replicas,READY:.status.readyReplicas
kubectl -n <ns> get deploy <app> -o jsonpath='{.status.conditions}'
```

Two ReplicaSets with `DESIRED=1` is the tell.

## Changing the alerts

Everything is Flux-managed — `kubectl edit` gets reverted. Edit the files above, open a PR, let
Flux reconcile.

Validate before pushing:

```bash
# rules
kubectl -n monitoring exec -i deploy/prometheus -- sh -c 'cat > /tmp/r.yml && promtool check rules /tmp/r.yml' \
  < kubernetes/flux/infrastructure/hawkfield/monitoring/alert-rules.yml

# routing (amtool needs the secret files to exist locally; point the *_file keys at dummies)
amtool check-config alertmanager.yml
```

The Prometheus and Alertmanager ConfigMaps are generated with content hashes, so a config change
produces a new ConfigMap name and forces a real rollout. A green Flux reconcile does mean the
process picked it up — unlike the `alloy-config` ConfigMap, which is pinned with
`disableNameSuffixHash` and still needs a manual restart.

## Known noise sources

- **Job and CronJob pods.** `kube_pod_container_status_restarts_total` counts retries of
  `restartPolicy: OnFailure` pods, so a retrying Job can trip the warning. Nothing currently
  does this often enough to matter; if one starts, exclude it with a label matcher on the rule
  rather than widening the threshold.
- **Node reboots.** A power event or node drain restarts everything at once and will produce a
  burst of warnings. See `hawkfield-power-cut-2026-08-02` for what that looks like.

## Not yet covered

- **No watchdog.** If Prometheus or Alertmanager is down, you get silence rather than an alert.
  The standard fix is an always-firing `Watchdog` rule routed to an external heartbeat service
  (healthchecks.io or similar) that alarms when the pings stop. Worth adding before relying on
  this pipeline for anything critical.
- **No alerting on anything other than restarts** — no disk, memory, certificate expiry, or
  target-down rules yet.
