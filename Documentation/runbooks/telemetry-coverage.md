# Runbook: telemetry coverage alerts

Covers `KubeletTelemetryMissing`, `CadvisorTelemetryMissing`, `NodeExporterTelemetryMissing`
(warning) and `KubeStateMetricsMissing` (critical), delivered to Telegram by Alertmanager.

## The alerts

| Alert | Severity | Fires when |
| --- | --- | --- |
| `KubeletTelemetryMissing` | warning | `up{job="kubelet"}` covers fewer than 3 nodes for 15m |
| `CadvisorTelemetryMissing` | warning | `up{job="cadvisor"}` covers fewer than 3 nodes for 15m |
| `NodeExporterTelemetryMissing` | warning | `up{job="integrations/unix"}` covers fewer than 3 `k8s-hawk-*` instances for 15m |
| `KubeStateMetricsMissing` | critical | no `kube_pod_info` series at all for 15m |

These exist because **none of these targets can ever be `up == 0`.** Prometheus does not scrape
any of them. They arrive by `remote_write` from the Alloy DaemonSet, so a sender that cannot
deliver makes its series stop arriving — the targets go *absent*, and every alert keyed on
`up == 0` is blind to it. Grafana panels do not error either; they just thin out.

`KubeStateMetricsMissing` is critical rather than warning because `PodRestartingFrequently` and
`PodCrashLooping` are both built on `kube_*` series. When it fires, those two alerts are not
"quiet" — they are incapable of firing.

The node count is hardcoded as 3. It cannot be derived, because the only source of a node count
is kube-state-metrics, which is one of the things that goes missing. **Adding a node means
editing these three expressions.**

## How the data reaches you

```
kubelet / cAdvisor / kube-state-metrics / node exporter
  → Alloy DaemonSet (scrape, one pod per node, hostNetwork)
  → remote_write http://prometheus.monitoring.svc:9090/api/v1/write
  → Prometheus → alert rules → Alertmanager → Telegram
```

The Alloy pods run `hostNetwork: true`, which is what makes them report the node rather than the
pod. It also means they have **no pod IP**, so no `podSelector` in any NetworkPolicy can match
them, and their traffic reaches Prometheus from the sending node's **Calico VXLAN tunnel
address** (in the pod CIDR, not the LAN range) whenever the two are on different nodes.

- Rules: `kubernetes/flux/infrastructure/hawkfield/monitoring/alert-rules.yml`
- Alloy config: `kubernetes/flux/infrastructure/base/monitoring/helm-release-alloy.yml`
- Policies: `kubernetes/flux/infrastructure/base/monitoring/network-policy.yml`
- Prometheus alert state: <https://prometheus.clinch-home.com/alerts>

## Triage

Check what is actually arriving:

```bash
kubectl -n monitoring exec deploy/prometheus -c prometheus -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=count%20by(job)(up)'
```

Then find which node is missing:

```bash
kubectl -n monitoring exec deploy/prometheus -c prometheus -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22kubelet%22%7D'
```

### 1. Is the sender alive?

```bash
kubectl -n monitoring get pod -l app.kubernetes.io/name=alloy -o wide
kubectl -n monitoring logs <alloy-pod> -c alloy --tail=50 | grep -i remote_write
```

A blocked or unreachable receiver looks like this, and **names nothing useful**:

```
level=warn msg="Failed to send batch, retrying" component_id=prometheus.remote_write.local
  err="Post \"http://prometheus.monitoring.svc:9090/api/v1/write\": context deadline exceeded"
level=error msg="final error sending batch, no retries left, dropping data"
```

`context deadline exceeded` on the POST means the TCP connection never completed. That is a
network path problem, not an Alloy problem.

### 2. Is a NetworkPolicy eating it?

This is what caused [#487](https://github.com/clincha-org/clincha/issues/487). Confirm on the
wire rather than by reading YAML — run this on the node **Prometheus** is on:

```bash
sudo tcpdump -nni any 'tcp port 9090 and tcp[tcpflags] & tcp-syn != 0'
```

A dropped flow arrives on `vxlan.calico In` and never appears on the destination's `caliXXXX`
interface, with the same sequence number retransmitting every few seconds and no SYN-ACK:

```
vxlan.calico In IP 10.233.103.0.49866 > 10.233.70.68.9090: Flags [S], seq 1781783217
vxlan.calico In IP 10.233.103.0.49866 > 10.233.70.68.9090: Flags [S], seq 1781783217
```

A permitted flow shows the `cali…  Out` hop and a SYN-ACK straight back.

Note the source address: `10.233.103.0` is **k8s-hawk-2's VXLAN tunnel address**, not
`10.1.2.102`. Map them with:

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.metadata.annotations.projectcalico\.org/IPv4VXLANTunnelAddr}{"\n"}{end}'
```

Only `ipBlock` rules can admit these senders. `allow-node-remote-write` and `allow-log-push` in
`network-policy.yml` are the two that do; if either loses its `ipBlock`, this breaks again.

### 3. Is only one node reporting?

If exactly one node survives, that node is almost certainly the one running the receiving pod —
node-local traffic never crosses the policy. That asymmetry is the signature of a policy
problem rather than a sender problem.

Logs have the same failure mode against a different receiver: the Loki gateway. When it bites
there, `{job="pod-logs"}` and the journal stream survive only for the node the gateway runs on,
while the `media` namespace sidecars keep working (they are pods, so `allow-log-push` matches
them by namespace). Per-node log counts can look healthy because those sidecar streams carry a
`node` label too — split by `job` before concluding anything:

```
sum by (node, job)(count_over_time({node=~"k8s-hawk-.*"}[10m]))
```
