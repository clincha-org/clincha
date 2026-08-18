# Runbook: UniFi network alerts

Covers the alerts built on the unpoller series from clincha#443, delivered to Telegram by
Alertmanager, plus the one network alert that cannot come from Hawkfield at all.

## The alerts

| Alert | Severity | Fires when |
| --- | --- | --- |
| `UniFiConsoleUnreachable` | critical | `unpoller_controller_up == 0` for 5m |
| `UniFiPollerRefreshFailing` | warning | 3+ refresh failures in 15m, sustained 5m |
| `UniFiWanLatencyHigh` | warning | WAN latency over 100ms for 15m |
| `UniFiInternetDropping` | warning | 3+ WAN drops in an hour |
| `UniFiAggregationLagMemberDown` | warning | fewer than 2 live members on the 2×1G LAG, for 10m |
| `UniFiAggregationLagMemberSlow` | warning | a LAG member negotiates below 1G, for 10m |
| `UniFiDevicesDisconnected` | warning | `unpoller_site_disconnected > 0` for 10m |
| `UniFiDeviceRebooting` | warning | 3+ uptime resets in an hour |
| `UniFiDeviceTemperatureHigh` | warning | any sensor over 85°C for 15m |
| `UniFiDeviceTemperatureCritical` | critical | any sensor over 90°C for 5m |
| `UniFiDeviceCpuHigh` | warning | CPU over 90% for 30m |
| `UniFiPoeBudgetHigh` | warning | PoE draw over 80% of the switch budget, for 30m |
| `UniFiSwitchPortErrors` | warning | over 1 error/s on a port for 15m |
| `UniFiWifiChannelUtilisationHigh` | warning | 5GHz channel over 75% utilised for 30m |
| `UniFiGatewayMemoryExhaustionPredicted` | warning | gateway headroom projected to reach earlyoom's threshold within 48h, for 2h |
| `UniFiGatewayMemoryCritical` | critical | gateway headroom already under earlyoom's threshold, for 15m |

Alerts carry `site` (`hawkfield` or `london`) and, where the metric has one, `name` — the device
name rather than its MAC.

## The thresholds are guesses. Treat them as provisional

#443 had been collecting for **three hours** when these rules were written, so not one threshold
is derived from a baseline. Each is set clear of observed idle:

| Signal | Observed idle (2026-08-10) | Threshold |
| --- | --- | --- |
| Bristol temperature | 67°C CPU / 71°C board | 85 warning, 90 critical |
| London temperature | 74°C CPU / 77°C board | 85 warning, 90 critical |
| Device CPU | 0.4–16.6% | 90% |
| WAN latency | 3–4ms | 100ms |
| 5GHz channel utilisation | peaks 55% (Kitchen) | 75% |
| Loft Switch PoE | 35.4W of a 95W budget | 80% of budget |

Revisit all of them once there are a couple of weeks of data. If one turns out to be noise, move
the threshold — do not mute the alert.

**Gateway memory has no rule at all.** Both UDMs idle at 83–86% memory utilisation, so a
conventional ">80%" rule fires the moment it lands and ">95%" has no evidence behind it. The
gateway is covered by CPU, temperature and `UniFiDeviceRebooting` instead, the last of which is
what an out-of-memory event actually looks like from outside.

Note also that the 83°C figure quoted in #445 for Bristol does not match any sensor the poller
exposes; the box reads 67°C CPU / 71°C board. Do not treat 83°C as Bristol's baseline.

## How the alert reaches you

```
UniFi consoles (10.1.2.1, 10.2.2.1) ┬→ unpoller (60s cache) → Prometheus (30s scrape)
                                    │      → alert rules → Alertmanager → Telegram (clincha_grafana_bot)
                                    └→ syslog UDP 514 → 10.1.2.210 (alloy-syslog) → Loki
```

unpoller **caches and serves; it does not poll on scrape**. Values are up to 60s stale, which is
why no rule here has a `for` shorter than 5m.

- Rules: `kubernetes/flux/infrastructure/hawkfield/monitoring/alert-rules.yml`
- Routing: `kubernetes/flux/infrastructure/hawkfield/monitoring/alertmanager.yml`
- Collector: `kubernetes/flux/infrastructure/base/monitoring/unpoller.yml` and
  `hawkfield/monitoring/up.conf`
- Console credentials: Bitwarden `unifipoller (Bristol)` / `unifipoller (London)` — read-only
  local accounts, verified as such
- Dashboard: Grafana uid `unifi-network`
- Logs: `kubernetes/flux/infrastructure/hawkfield/monitoring/config-syslog.alloy` and
  `base/monitoring/alloy-syslog.yml`

Metric names are prefixed **`unpoller_`, not `unifi_`** — renamed in unpoller v3. Older blog
posts and community dashboards all use the old prefix and will silently match nothing.

## The UniFi logs

Every UniFi device forwards syslog to `10.1.2.210:514`, a UDP listener on the `alloy-syslog` pod
that pushes straight to Loki. Start here when a rule above fires — it is the only device-side
detail available without SSH.

**It is not just the consoles.** Enabling remote logging on a console enables it on everything
that console has adopted, so the stream is both gateways plus all nine Hawkfield APs and switches.
That is the useful half: `hostapd` and `stahtd` lines are what explain a WiFi alert. It is also
around 1.2M lines/day, most of it AP `kernel` driver chatter and the consoles' `LAN_LOCAL`
firewall logging — kept deliberately (Angus, 2026-08-11), so do not "fix" the volume.

```logql
{job="unifi-syslog"}
{job="unifi-syslog", site="hawkfield"}
{job="unifi-syslog", site="london"}
{job="unifi-syslog", severity=~"error|critical|alert|emergency"}
{job="unifi-syslog", daemon="hostapd"}
{job="unifi-syslog", host="Paddock"}
```

Five labels: `job`, `site`, `host` (the reporting device), `daemon` and `severity`.

`daemon` is **not** the syslog tag, because on this kit the tag is useless: the consoles emit their
hostname a second time where the tag belongs, so the parser finds no tag at all, and the APs put
`<mac>,<model>` there. It is recovered from the first token of the message body instead. Lines that
open with a bracket — the firewall's `LAN_LOCAL` rules — have no daemon and carry no such label.

`site` is derived from the **hostname in the message**: `London` → `london`, the ten known
Hawkfield devices → `hawkfield`, anything else → `unknown`, with the reported name kept verbatim in
`host`.

**It is deliberately not the packet source IP.** London reaches Hawkfield over a Tailscale subnet
route and the Bristol gateway SNATs it, so London's packets arrive with source `10.1.2.1` — the
same address Bristol's own packets carry. Source-IP rules would have labelled the entire London
stream `hawkfield` and nothing would have looked wrong. Verified 2026-08-10 by capturing UDP from
both consoles on `k8s-hawk-2`.

So `{job="unifi-syslog", site="unknown"}` returning rows means a device was renamed, a new one was
adopted, or a sender nobody has accounted for; check `host` and add it to the alternation in
`config-syslog.alloy`.

⚠️ **A device adopted at London will land on `unknown`, and that is the best available answer.**
Its packets are SNAT'd to Bristol's address like the London console's, and nothing inside a syslog
message says which site it came from — so an unrecognised name genuinely cannot be attributed.
Resist the temptation to default the catch-all to `hawkfield`: it would be right today and
silently wrong the moment Angus puts an AP in the flat.

### Caveats worth knowing before you trust a gap

- **UDP, so loss is silent.** UniFi's `ubios-udapi-server` has exactly one `transport()` literal
  and it is `udp`; there is no TCP setting to pick. An empty window is not evidence that nothing
  happened. Accepted deliberately — do not read absence as an all-clear.
- **A rollout drops a few seconds.** Single-replica Deployment; while the pod moves, nothing is
  listening.
- **Not the UniFi OS journal.** The gateways' own `unifi-core`, mongo and UniFi OS kernel messages
  stay on the box and still need SSH. AP `kernel` lines do arrive; UDM ones do not.
- **RFC3164.** UniFi emits BSD-format syslog, so the listener sets `syslog_format = "rfc3164"`.
  Alloy's default is rfc5424 and would mangle every message. Note the consoles set
  `ts_format(iso)` globally in `/etc/syslog-ng/syslog-ng.conf`, which is why `/var/log/messages`
  on the box carries ISO timestamps — it does **not** apply to the `network()` destination, whose
  wire format is a plain BSD stamp (`<30>Aug 10 15:38:25 Bristol udapi-probe: …`, captured).

Console-side the setting is Network → Settings → System → **Remote logging**, persisted as the
`rsyslogd` document in each console's Mongo: `enabled: true`, `this_controller: false` (true means
"keep them here"), `ip: 10.1.2.210`, `port: 514`.

If the stream stops, check the pod before the consoles:

```bash
kubectl -n monitoring logs deploy/alloy-syslog --tail=50
kubectl -n monitoring get svc alloy-syslog
```

The TrueNAS stream (`{job="truenas-syslog"}`) is a separate TCP listener on `10.1.2.210` in the
same pod, so it flowing while UniFi does not narrows the fault to the UDP path or the consoles.

## The one alert that cannot come from Hawkfield

**Hawkfield cannot alert on the loss of its own WAN.** Prometheus, Alertmanager and the only
route to Telegram all sit behind it. Every rule above goes silent in exactly the event you most
want to hear about.

That alert is the `hawkfield gateway` monitor on the London watchdog
(`terraform/watchdog/main.tf`), which probes **10.1.2.1:443 over the site-to-site link**, not the
WAN IP. The WAN IP drops ICMP and opens only 443, and that 443 is the ingress port-forward — so
probing `185.23.254.226` would only duplicate the existing `hawkfield public` monitor rather than
isolate the WAN.

Hawkfield has a single WAN and the VPN rides it, so one probe covers WAN loss, site-link loss and
a site power cut. Read it alongside the public monitor:

| `hawkfield gateway` | `hawkfield public` | Means |
| --- | --- | --- |
| down | down | WAN, site-to-site link, or site power |
| up | down | ingress, the cluster, or the port-forward |
| down | up | site-to-site link only — the site is fine and reachable publicly |

If **both** sites go dark at once, nothing alerts. That is a known and accepted gap.

## Quiet hours

Warnings are muted 23:00–06:00 Europe/London; criticals are never muted. Muting suppresses, it
does not queue — a warning that fires *and resolves* inside the window is never announced.

Only `UniFiConsoleUnreachable` and `UniFiDeviceTemperatureCritical` are critical, so those two
are the only network rules that will wake you. Everything else waits for 06:00. The London
watchdog notifies through its own Telegram path and is not subject to this mute at all.

## Triage

### `UniFiConsoleUnreachable`

The summary deliberately does not claim the console is down, because from Hawkfield the two cases
are indistinguishable — the poller sits at Hawkfield, so London going unreachable could equally
be the site-to-site link.

```bash
# Which console, and is it the box or the path?
curl -sk https://10.1.2.1/api/system | jq .        # Bristol, answers unauthenticated
curl -sk https://10.2.2.1/api/system | jq .        # London, over the site link

# If London is unreachable, check whether anything else at London answers
ping -c3 10.2.2.101
```

Bristol unreachable while the cluster is up means the console itself. London unreachable while
`10.2.2.101` also fails to answer means the link, not the console. Check the watchdog's own view
before concluding anything about London.

If both consoles report unreachable simultaneously, suspect the poller rather than two
independent console failures:

```bash
kubectl -n monitoring logs deploy/unpoller --tail=50
kubectl -n monitoring get pods -l app=unpoller
```

### `UniFiDevicesDisconnected`

The alert is site-and-subsystem level and does not name the device, because whether an offline
device is dropped from the export or merely reported stale has not been confirmed against a real
outage. Name it by comparing against the adopted count and the device list:

```promql
# which subsystem, how many
unpoller_site_disconnected > 0

# every device the poller can currently see, by name
unpoller_device_info

# devices seen two hours ago but not now
max_over_time(unpoller_device_uptime_seconds[2h]) unless unpoller_device_uptime_seconds
```

Hawkfield should show 10 devices: the Bristol UDM, `Loft Switch`, `USW Aggregation`, and seven
APs (`Hall`, `Kitchen`, `Living Room`, `Master Bedroom`, `First Floor Landing`, `Loft Landing`,
`Paddock`). London has the console only.

`Paddock` is an outbuilding AP and the most likely to drop for reasons that are not a fault.

### `UniFiAggregationLagMemberDown` — read this one carefully

This is the alert most likely to catch something nothing else would.

`USW Aggregation` carries the 10G spine: the cluster nodes and hawkstore hang off ports 2–6 at
10G. Its uplink to the rest of the LAN is a **two-member LAG on ports 7/8 into Loft Switch ports
25/26, negotiating 1 Gbps per member** — the USL24P's SFP ports are 1G-only, so 2 Gbps is as fast
as the hardware goes. That is not a fault.

Lose one member and north-south capacity halves to 1 Gbps **silently**. Traffic that stays on the
aggregation switch is unaffected, so NFS between the cluster and the NAS still runs at 10G and
looks perfectly healthy. Anything crossing the uplink degrades. From every other panel this
presents as "the NAS is slow" or "Plex is buffering" — which is the shape of the last two
incidents in this estate.

```promql
# per-member negotiated speed; expect two series at 1e9
unpoller_device_port_port_speed_bps{name="USW Aggregation", port_num=~"7|8"}

# throughput per member — are both actually passing traffic?
rate(unpoller_device_port_receive_bytes_total{name="USW Aggregation", port_num=~"7|8"}[5m])
```

Check the physical SFP and the patch at both ends before assuming a switch fault. A LAG running
on one leg reports no error anywhere else.

Note that a two-member LAG does not split a single TCP flow, so one heavy transfer sees 1 Gbps
even when both members are healthy. Do not read that as a fault.

### Temperature alerts

Bristol sits in the loft; London is in the Solon Road flat and runs the hotter of the two. Both
are UDM gen 1 with passive cooling, so ambient temperature moves them directly — a warning during
a heatwave is more likely to be the room than the box.

```promql
unpoller_device_temperature_celsius
max_over_time(unpoller_device_temperature_celsius[7d])
```

Check airflow and dust before anything else. A gateway that is both hot and rebooting
(`UniFiDeviceRebooting`) is a hardware conversation, not a tuning one.

### `UniFiSwitchPortErrors`

Almost always a cable, an SFP, or a duplex mismatch — in that order of likelihood.

```promql
rate(unpoller_device_port_receive_errors_total[15m]) > 0
rate(unpoller_device_port_transmit_errors_total[15m]) > 0
unpoller_device_port_sfp_rx_power   # for the 10G SFP+ ports
```

Falling `sfp_rx_power` on a port that is throwing errors points at the optic or the fibre.

### `UniFiGatewayMemoryExhaustionPredicted` / `UniFiGatewayMemoryCritical`

A UDM idles at 83–86% memory used, so these two rules deliberately ignore utilisation and watch
**headroom** — `installed - used`, which is MemAvailable, because unpoller reports `used` as
`MemTotal - MemAvailable`. Both thresholds are `earlyoom`'s own `-M 256000` (kB), not a guess.

The failure this catches is #480: `unifi-core` leaks, `earlyoom` is configured to `--avoid`
`unifi-core`, so when memory runs out it SIGTERMs the **UniFi Network application** instead.
The console dies, the router does not. Expect a report of "the router is down" when routing,
DNS and WAN are all fine.

```bash
# headroom now, both consoles
curl -s http://unpoller.monitoring.svc:9130/metrics \
  | grep -E '^unpoller_device_memory_(installed|used)_bytes.*udm'

# what is actually holding the memory — needs the console
ssh root@10.1.2.1 'grep -E "MemAvailable|SwapFree" /proc/meminfo'
ssh root@10.1.2.1 'ps -eo comm,rss,vsz --sort=-rss | head'

# per-process history the box keeps itself, every 5 minutes.
# Sum VmRSS + VmSwap — a large share of the growth sits in swap.
ssh root@10.1.2.1 \
  "awk -F, '/^timestamp,/{ts=\$3} /^unifi-core,unifi-core,/{print ts,\$6,\$7}' \
     /var/log/mem_trend/mem_trend_long.csv"

# earlyoom's own verdict
ssh root@10.1.2.1 'journalctl -u earlyoom --since -7d | tail -40'
```

`UniFiGatewayMemoryExhaustionPredicted` stays silent until it has **20 hours** of history for a
console, and fits the raw metrics rather than the recorded `gateway:unifi_memory_available_bytes:avg3h`.
Both are deliberate: a `predict_linear` with only minutes of data extrapolates noise, which is
exactly how this rule went pending on both consoles the moment it was deployed. Silence in the
first day after a TSDB rebuild, or on a newly adopted console, is the rule working.

**To recover:** `systemctl restart unifi-core` on the affected console. It reclaims the leak
(~160 MB in the 2026-08-17 case), routing and WAN are unaffected, and unpoller reconnects on its
own — it does not need touching. Restarting the *Network application* instead, which is what the
console's Start button does, reclaims nothing: it kills the victim, not the leaker.

This is a reset, not a fix. Confirm the slope afterwards rather than assuming it is gone.

### `UniFiWifiChannelUtilisationHigh`

5GHz only. 2.4GHz is deliberately not alerted on: it already peaks over 50% at idle here from
neighbouring networks and IoT devices, and there is nothing actionable to do about it.

This is the signal that would have shown the ~30 Mbps WiFi ceiling behind the 33.8 Mbps Plex
remux stuttering, months before it was diagnosed by hand.

```promql
unpoller_device_radio_channel_utilization_total_ratio{band="5"}
unpoller_device_radio_channel{band="5"}     # are two APs sharing a channel?
unpoller_device_radio_stations{band="5"}    # client count per radio
```

## Changing the alerts

```bash
# rules
kubectl -n monitoring exec -i deploy/prometheus -- sh -c 'cat > /tmp/r.yml && promtool check rules /tmp/r.yml' \
  < kubernetes/flux/infrastructure/hawkfield/monitoring/alert-rules.yml

# unit tests, which run in CI too
promtool test rules kubernetes/alert-rule-tests/unifi-network.yaml
```

Rules land through Flux. A green reconcile means the ConfigMap changed, **not** that Prometheus
reloaded it — confirm against <https://prometheus.clinch-home.com/rules> before believing a
change is live.

## Known noise sources

- **Paddock AP** — outbuilding, most likely to disconnect for benign reasons.
- **2.4GHz utilisation** — over 50% at idle. Not alerted on, and should stay that way.
- **Gateway memory at 83–86%** — normal for a UDM. Still not alerted on as a *utilisation*
  threshold; #480 added a trend rule on headroom instead. See below.
- **Firmware updates** — `unpoller_device_upgradable` exists and is 0 across the estate, but
  there is no rule. An informational alert has no severity that routes anywhere except the
  unmuted default, so it would arrive overnight. Add it as a dashboard panel instead.

## Not yet covered

- **Both sites dark simultaneously.** Hawkfield and London watch each other; nothing watches the
  pair. A deliberate choice — do not re-propose a third-party dead-man's switch without asking.
- **Per-client alerting.** Client series exist (`unpoller_client_*`) but a per-client alert on a
  home network is noise by construction.
- **Verification against real conditions.** See the verification note on #445 — several rules
  here have only ever been exercised against replayed series, not an induced fault.
