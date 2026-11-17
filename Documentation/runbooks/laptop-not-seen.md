# Runbook: laptop not seen

Covers `LaptopNotSeen` (warning): `clincha-laptop` has sent no `up{job="integrations/unix"}`
sample to Prometheus for 10 days. The laptop is normally off, so this is a reminder to power it on
and let it take updates, not an outage.

Alloy on the laptop remote-writes to Prometheus, and drops samples while it is away from the
network. The alert clears by itself once the laptop is on and connected again.

## Check

```bash
curl -s https://prometheus.clinch-home.com/api/v1/query \
  --data-urlencode 'query=up{job="integrations/unix", instance="clincha-laptop"}'
```

## If it was on and still alerts

- `ssh dave@100.76.6.19` (Tailscale IP) and `systemctl status alloy`.
- Check the laptop can reach `prometheus.clinch-home.com` (on the LAN or over the tailnet).
