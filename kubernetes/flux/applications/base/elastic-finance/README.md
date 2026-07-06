# Elastic Finance

Elastic instance to host financial data, graphs and dashboards.

Helm chart: https://github.com/elastic/cloud-on-k8s/tree/main/deploy/eck-stack

Available roles for users: https://www.elastic.co/docs/reference/elasticsearch/roles

## Dashboard backup and restore

Kibana dashboards are saved objects held in the `.kibana` indices, so a full
cluster rebuild destroys them even though the Longhorn volumes survive pod
restarts. To make dashboards reproducible from the build, they are exported to
NDJSON, committed under `dashboards/`, and re-imported automatically on every
deploy by the `kibana-dashboard-import` Job.

The Job waits for Kibana to be ready, then imports every `dashboards/*.ndjson`
file via the Saved Objects `_import` API with `overwrite=true`, so it is
idempotent and safe to re-run. Empty files are skipped, so committing dashboards
is optional until you have some.

### Export (run whenever dashboards change, then commit)

Port-forward Kibana and export the saved objects you want to keep. Credentials
come from the `secret-basic-auth` secret.

```bash
kubectl -n elastic-finance port-forward svc/kibana-kb-http 5601:5601 &

curl -sf -u "$USER:$PASS" \
  -H "kbn-xsrf: true" \
  -X POST "http://localhost:5601/api/saved_objects/_export" \
  -H "Content-Type: application/json" \
  -d '{"type":["dashboard"],"includeReferencesDeep":true}' \
  -o dashboards/dashboards.ndjson
```

Commit the updated `dashboards/dashboards.ndjson`. On the next reconcile the
import Job restores it; after a cluster rebuild the dashboards come back with no
manual steps.

