# hawkstore TLS certificate

How the TrueNAS web UI on hawkstore (`10.1.2.10`) serves a real Let's Encrypt certificate instead
of the stock self-signed one, and what to do when it needs attention.

hawkstore is **not managed as code** — certificates, the ACME account and the DNS authenticator
are all configured through the TrueNAS UI/API, so this page is the only record. If you change any
of it, change this page in the same sitting.

Set up **2026-08-13**. Before that the box served the factory `truenas_default` certificate
(`CN=localhost`, issued by iXsystems), so every visit to the UI threw a browser warning.

## Current state

| | |
|---|---|
| Certificate | id **3**, `hawkstore_le` |
| Common name | `hawkstore.clinch-home.com` |
| SANs | `DNS:hawkstore.clinch-home.com`, `DNS:nas.clinch-home.com` |
| Key | EC, `SECP384R1` |
| Issuer | Let's Encrypt (production) |
| Expires | 2026-11-11, renews automatically at 10 days remaining |
| Signing request | id **2**, `hawkstore_acme_csr` |
| DNS authenticator | id **1**, `cloudflare-clinch-home` |

Both hostnames already resolve to `10.1.2.10` on the LAN through AdGuard — see
`adguard_local_dns_entries` in `Ansible/group_vars/adguard.yml`. No DNS work was needed.

The old `truenas_default` certificate is still present as id 1. It is unused and deliberately
left in place; TrueNAS regenerates it if it is missing.

## Browse to the hostname, not the IP

A publicly trusted CA cannot issue for an RFC1918 address, so `https://10.1.2.10` will always
throw a certificate warning no matter what is installed. Use `https://hawkstore.clinch-home.com`.

This applies to scripts too. Anything talking to the REST API by IP still needs `curl -k`;
anything using the hostname can drop it.

## Why the NAS issues its own certificate

The cluster already runs cert-manager with a `letsencrypt` ClusterIssuer using the same Cloudflare
DNS-01 method, so an obvious alternative was to have cert-manager issue the certificate and push
it onto the NAS. That was rejected: it needs a CronJob to copy a Kubernetes secret onto the box on
a schedule, which is a hand-rolled moving part for something TrueNAS does natively. The built-in
renewal job is `certificate.renew_certs`, a `@periodic(86400)` task, so there is nothing to write
and nothing to maintain.

Proxying the UI through ingress-nginx was also rejected. It would put the storage administration
interface behind a cluster whose Prometheus, Grafana and Loki data all live on that same NAS — a
circular dependency on the exact box you would be logging in to repair.

## The Cloudflare token

Stored in Bitwarden as **`hawkstore-acme`**. Scoped to:

- **Zone → DNS → Edit** on `clinch-home.com`
- **Zone → Zone → Read** on `clinch-home.com`

Both are required. TrueNAS calls certbot's `_CloudflareClient`, whose `_find_zone_id()` looks the
zone up by name **before** writing the challenge record. A token holding only `DNS:Edit` fails at
that lookup and reports `Did you enter a valid Cloudflare Token?`, which reads like a bad token
rather than a missing permission.

Scoped to `clinch-home.com` alone, deliberately. The cluster's cert-manager token
(`cloudflare-api-token-secret`, namespace `certificate-manager`) covers both `clinch-home.com` and
`clincha.co.uk`; reusing it would mean a NAS compromise handing over certificate issuance for the
whole estate. No client IP filter — the home WAN address is not static, and a renewal failing at
03:00 because the address rolled is worse than the marginal gain.

## Rebuilding it

All of this is equally doable in the UI under **Credentials → Certificates**. API form, with a
`dave` API key in `$KEY`:

```bash
# 1. DNS authenticator
curl -sk -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data @auth.json https://10.1.2.10/api/v2.0/acme/dns/authenticator
# auth.json: {"name":"cloudflare-clinch-home",
#             "attributes":{"authenticator":"cloudflare","api_token":"<token>"}}

# 2. CSR  (returns a job id — poll core/get_jobs?id=N)
curl -sk -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data '{"create_type":"CERTIFICATE_CREATE_CSR","name":"hawkstore_acme_csr",
           "common":"hawkstore.clinch-home.com",
           "san":["hawkstore.clinch-home.com","nas.clinch-home.com"],
           "key_type":"EC","ec_curve":"SECP384R1","digest_algorithm":"SHA256",
           "country":"GB","state":"England","city":"London","organization":"clincha",
           "email":"angus.clinch@gmail.com"}' \
  https://10.1.2.10/api/v2.0/certificate

# 3. ACME certificate from that CSR (also a job; ~2.5 min for DNS propagation)
curl -sk -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data '{"create_type":"CERTIFICATE_CREATE_ACME","name":"hawkstore_le","csr_id":2,
           "acme_directory_uri":"https://acme-v02.api.letsencrypt.org/directory","tos":true,
           "dns_mapping":{"hawkstore.clinch-home.com":1,
                          "DNS:hawkstore.clinch-home.com":1,
                          "DNS:nas.clinch-home.com":1},
           "renew_days":10}' \
  https://10.1.2.10/api/v2.0/certificate

# 4. Point the GUI at it, then restart the UI
curl -sk -X PUT -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data '{"ui_certificate":3}' https://10.1.2.10/api/v2.0/system/general
curl -sk -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '3' https://10.1.2.10/api/v2.0/system/general/ui_restart
```

### `dns_mapping` keys must match the CSR exactly

`certificate.get_domain_names <csr_id>` returns the common name **both bare and `DNS:`-prefixed**,
but a SAN-only name **only** prefixed:

```
["hawkstore.clinch-home.com", "DNS:hawkstore.clinch-home.com", "DNS:nas.clinch-home.com"]
```

The validator normalises the mapping into a copy, then checks the **raw** keys you supplied
against that list. A bare `nas.clinch-home.com` is therefore rejected with
`nas.clinch-home.com not specified in the CSR` even though it is plainly in the SANs. Supply all
three forms. This matters beyond first issuance: renewal replays the stored
`domains_authenticators`, so a mapping that was wrong at creation fails silently months later.

### `ui_restart` takes a bare integer

`POST system/general/ui_restart` wants `-d '3'`, not `{"delay":3}` — the same shape quirk as
`filesystem/stat`, which takes a bare JSON string. An object body returns
`Input should be a valid integer`.

More importantly, **setting `ui_certificate` does not reload the listener**. The PUT returns 200
and the box carries on serving the previous certificate until the UI is restarted. Verify what is
actually on the wire rather than trusting the write.

### API responses contain secrets

`acme/dns/authenticator` returns `api_token` in cleartext on **both create and read**, despite the
field being typed `Secret[]` in the API model — that annotation is documentation of intent, not a
guarantee. `system/general` embeds the GUI certificate's private key, and `certificate/id/N`
embeds the certificate private key.

Never dump a whole response object from these endpoints. Print named fields only.

## Verifying

```bash
for h in hawkstore.clinch-home.com nas.clinch-home.com; do
  echo | openssl s_client -connect "$h:443" -servername "$h" -verify_hostname "$h" 2>&1 \
    | grep -E 'subject=CN|Verify return code'
  curl -s -o /dev/null -w "$h %{http_code} verify=%{ssl_verify_result}\n" "https://$h/"
done
```

`verify=0` and `Verify return code: 0 (ok)` with no `-k` is the goal.

## Renewal

`certificate.renew_certs` runs every 86400 seconds. It selects every certificate with a non-null
`acme` field, renews any whose remaining life is under its `renew_days`, and writes the result
back to the **same certificate id** — so the `ui_certificate` reference never needs re-pointing
and no restart is required.

Renewal reuses the stored `domains_authenticators` mapping and the stored Cloudflare token. It is
the only thing that needs the token to keep working; an already-issued certificate is unaffected
by token changes, because its private key is generated on the NAS and never touches Cloudflare.

## Rotating the Cloudflare token

The token was rolled once on 2026-08-13. Procedure:

1. Cloudflare → My Profile → API Tokens → `hawkstore-acme` → **Roll**. This keeps the same token
   id and its permissions and changes only the value, so there is nothing to re-scope.
2. Update the `hawkstore-acme` item in Bitwarden.
3. Preflight the new value before touching the NAS — look the zone up by name, create a throwaway
   TXT record and delete it again. That exercises exactly what certbot does at renewal and catches
   a missing `Zone:Read` immediately instead of in November.
4. Push it into the authenticator:

```bash
curl -sk -X PUT -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data @upd.json https://10.1.2.10/api/v2.0/acme/dns/authenticator/id/1
# upd.json: {"attributes":{"authenticator":"cloudflare","api_token":"<new token>"}}
```

5. Confirm the old value is dead: `GET /user/tokens/verify` with it should return
   `1000 Invalid API Token`.

## Certificate Transparency

`hawkstore.clinch-home.com` and `nas.clinch-home.com` are published to public CT logs as a
consequence of using a public CA. This is already true of `grafana`, `prometheus`, `loki` and the
rest of the ingress hostnames, so it is not a new class of exposure, but internal naming does
leak. An internal CA would avoid it and would cover the IP as well, at the cost of distributing a
root certificate to every device — not worth it for one box.

## Related

- [apps.md](apps.md) — what each TrueNAS app on the NAS is for
- [backup-policy.md](backup-policy.md) — snapshot and replication tasks
- `kubernetes/flux/infrastructure/base/certificate-manager/` — the cluster's separate cert-manager
  setup, which issues for the ingress hostnames using the same Cloudflare DNS-01 method
