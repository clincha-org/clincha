# Runbook: Plex SQLite connection pool

Covers `PlexDatabasePoolStalled` and `PlexLogMetricsMissing` (both warning), delivered to
Telegram by Alertmanager.

## The alerts

| Alert | Severity | Fires when |
| --- | --- | --- |
| `PlexDatabasePoolStalled` | warning | more than 10 `waiting on db connections` log lines in 5m |
| `PlexLogMetricsMissing` | warning | `alloy_build_info{job="plex-logs-sidecar"}` absent for 30m |

## What the first one means

Plex serialises every write through a small SQLite connection pool. When one client floods it,
all the connections end up held by `/:/timeline` playback-progress writes contending on the same
`MetadataItemSetting` transactions, and the pool deadlocks against itself. Playback and browsing
hang for as long as it lasts.

**The known trigger is scrubbing backwards and forwards on a TV player.** Each seek fires a
timeline update, and they arrive faster than they commit.

The reason this needs its own alert is that **nothing else in the estate can see it**:

- the pod stays `Running 2/2` with no restarts
- `/identity` answers in **under a millisecond throughout**, because it takes no database
  connection — it is worthless as a health check for this failure
- CPU, memory and NFS latency all look normal, because the pipe is not the problem

On 2026-09-02 this made Plex unusable for about six minutes while every dashboard stayed green.
Requests that needed the database took up to **377,923 ms**. It recovered on its own the instant
the client stopped playback.

## The threshold is measured, not guessed

Counting `waiting on db connections` in Loki over the 30 days to 2026-09-02: quiet days produce
**exactly zero**. Six days had any at all — 11, 22, 68, 83, 342 and 347 lines. One line is
emitted per waiting thread, so a real stall produces dozens within seconds. `> 10 in 5m` sits
below the smallest observed incident and above a silence that never happens.

## How the data reaches you

```
Plex Media Server.log  (file on the /config NFS volume, never stdout)
  → Alloy sidecar in the Plex pod  (loki.process stage.metrics counter)
  → self-scrape 127.0.0.1:12345  →  remote_write prometheus.monitoring.svc:9090
  → Prometheus → alert rules → Alertmanager → Telegram
```

The counter is `plex_db_pool_waits_total`, defined in `config/plex-logs.alloy` in the
**`clincha/media` repo**, not this one. The sidecar's `allow-node-remote-write` path is already
permitted: the policy admits the whole pod CIDR `10.233.64.0/18`, which covers the Plex pod.

`PlexLogMetricsMissing` exists because `plex_db_pool_waits_total` **does not exist until its
first match**, so it cannot carry an `absent()` guard of its own. `alloy_build_info` rides along
from the same scrape of the same sidecar. If it stops arriving, `PlexDatabasePoolStalled` has
gone blind in exactly the way a healthy Plex looks.

## When `PlexDatabasePoolStalled` fires

**Do not restart the pod first.** A bounce clears the symptom and destroys the evidence, and the
stall usually ends on its own within minutes anyway.

1. Check whether it is still happening:

   ```bash
   POD=$(kubectl get pod -n media -l app=plex -o name | head -1)
   L="/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"
   kubectl exec -n media ${POD#pod/} -c plex -- sh -c "grep 'waiting on db connections' '$L' | tail -3"
   kubectl exec -n media ${POD#pod/} -c plex -- sh -c "grep 'Took too long' '$L' | tail -5"
   ```

2. Find what is actually holding the pool. Every held connection in the 2026-09-02 incident was
   a timeline write for one `ratingKey`:

   ```bash
   kubectl exec -n media ${POD#pod/} -c plex -- sh -c "grep 'Completed:' '$L' | tail -200" \
     | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+ms$/){gsub(/ms/,"",$i); if($i+0>1000) print}}'
   ```

   If the slow entries are all `/:/timeline` for the same title, it is the known pattern — a
   client seeking repeatedly. It will clear when playback stops.

3. Confirm storage is not the cause before blaming it. Normal looks like this:

   ```bash
   kubectl exec -n media ${POD#pod/} -c plex -- sh -c \
     'S=$(date +%s%N); dd if=/dev/zero of=/config/.lat bs=1M count=20 oflag=dsync 2>/dev/null; \
      E=$(date +%s%N); echo "$(( (E-S)/1000000 )) ms"; rm -f /config/.lat'
   ```

   ~750 ms for 20 MB and 8 ms directory stats is healthy. Bandwidth being fine does **not**
   exonerate NFS — the cost here is lock acquisition and fsync round trips, not throughput.

4. Only restart if it has not cleared and playback is still broken. `Recreate` strategy is
   required for anything on a shared NFS file — a `RollingUpdate` deadlocks on the lock.

## The underlying fix

The databases (`com.plexapp.plugins.library.db`, ~87 MB, and its blobs sibling, ~174 MB) live on
NFS at `10.1.2.10:/mnt/userstore/plex`. SQLite over NFS pays for every lock and fsync over the
wire. Moving them off, and replacing the ZFS snapshot/replication coverage that move gives up,
is tracked in **clincha/media#99**.

Until that lands, this alert is the only thing that will tell you the outage happened.
