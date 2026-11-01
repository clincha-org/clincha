# Runbook: media queue stuck

Covers `MediaQueueStuck`: a Sonarr or Radarr queue item in a `warning` or `error` status for over
an hour. Nothing retries these, so a human has to clear them. Nothing auto-fixes them either — an
auto-fixer was tried and dropped.

The series come from `media-exporter` (clincha/media, `config/media-exporter.py`):
`media_queue_stuck_items{app,status,reason}`, refreshed every 15 minutes.

## Reasons

| `reason` | Sonarr/Radarr says | Usual cause |
| --- | --- | --- |
| `unsafe_extension` | "Found executable file with extension '.exe'" | Some releases are named `.exe`. Most are real video; one seen in 2026-09 was a genuine Windows PE binary (`MZ` header) served under several show names. Check the file before trusting it. |
| `archive_not_extracted` | "Found archive file, might need to be extracted" | SABnzbd sometimes skips unrar on a multi-episode NZB and still marks it Completed (seen 2026-09 on a season pack, no unrar in `sabnzbd.log`). |
| `id_only_match` | "matched to series/movie by ID. Automatic import is not possible" | Release naming Sonarr/Radarr can only match through grab history. Import it by hand. |
| `other` | anything else | Read the queue item's status message. |

## Triage

Open Activity → Queue in Sonarr or Radarr; the item's status message says what blocked it.

```bash
kubectl -n media exec deploy/sonarr -c sonarr -- sh -c 'curl -s \
  "http://localhost:8989/api/v3/queue?includeUnknownSeriesItems=true&pageSize=250" \
  -H "X-Api-Key: $(grep -o "<ApiKey>[^<]*" /config/config.xml | cut -d">" -f2)"' \
  | jq -r '.records[] | select(.trackedDownloadStatus != "ok") | [.title, .outputPath, (.statusMessages[].messages[])] | @tsv'
```

- **`unsafe_extension`:** check the first bytes (`head -c2 file` is `MZ` for a real executable). A real
  executable: delete it and blocklist the release without re-searching. A real video: blocklist and
  search again, or rename it and import manually.
- **`archive_not_extracted`:** extract with a real `unrar` (the SABnzbd container has one) into local
  scratch, then move the result into the download folder. Extracting straight onto the NFS mount
  silently lost files in testing.
- **`id_only_match`:** Manual Import in the UI.

## Where things live

- Metric: `config/media-exporter.py` in clincha/media, `collect_queues()`
- Rule: `kubernetes/flux/infrastructure/hawkfield/monitoring/alert-rules.yml`
- Routing: `kubernetes/flux/infrastructure/hawkfield/monitoring/alertmanager.yml`

Warnings are muted 23:00–06:00; one raised overnight arrives after 06:00.
