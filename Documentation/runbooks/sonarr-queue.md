# Runbook: Sonarr queue stuck alert

Covers `SonarrQueueStuck`, built on `media_sonarr_queue_warning_items` from the media-exporter
(clincha/media, `config/media-exporter.py`).

## Background

Sonarr's import queue can get stuck in a `warning` tracked-download status without ever
"failing" — the download completed, but Sonarr refuses to import it. Debugged 2026-09-22 against
a real backlog; three distinct causes were found, two of which are auto-fixed:

| Reason label | Cause | Auto-fixed? |
| --- | --- | --- |
| `unsafe_extension` | Sonarr's import-safety check refuses any file with an executable extension. Usually a release group genuinely shipped the video misnamed `.exe`; occasionally it's a real Windows PE binary (decoy/malware release) served under a plausible show name. | Yes — `sonarr-queue-fixer` checks the file's magic bytes. A real video gets blocklisted and Sonarr searches again. A genuine PE header (`MZ`) gets deleted and blocklisted **without** an automatic re-search, so a poisoned indexer can't be looped into re-grabbing another disguise of the same payload. |
| `archive_not_extracted` | SABnzbd splits a multi-story usenet NZB (e.g. a season pack) into one subfolder per story, but its unpacker can silently skip invoking `unrar` for some of them and still mark the whole job Completed. The raw multi-volume RAR set is left behind. | Yes — the fixer tests the archive, extracts it to local scratch space and moves the result into place (extracting straight onto the NFS mount was tried first and silently lost files on some runs — see the script's comments), deletes the raw volumes, and nudges Sonarr to rescan. |
| `id_only_match` | An anthology/factual show (e.g. a long-running documentary series) is released with naming that Sonarr can only match to a series via grab-history ID, not by title. Sonarr explicitly refuses to auto-import an ID-only match. | No — there is no safe way to confirm the match without a human. Always needs manual import in the Sonarr UI. |

The fixer runs every 15 minutes (`applications/sonarr-queue-fixer.yml` in clincha/media). The
alert fires at 30 minutes specifically so the fixer gets two passes first — anything still stuck
after that is either the unfixable third class or a genuinely new failure mode.

## Triage

```bash
# what's actually stuck right now, and why
curl -s "http://sonarr.media.svc:8989/api/v3/queue?includeUnknownSeriesItems=true&pageSize=250" \
  -H "X-Api-Key: $SONARR_API_KEY" | jq -r '.records[] | select(.trackedDownloadStatus=="warning") |
  [.title, (.statusMessages[].messages[])] | @tsv'

# is the fixer actually running and what did it do last
kubectl -n media get jobs -l name=sonarr-queue-fixer
kubectl -n media logs -l name=sonarr-queue-fixer --tail=100
```

- `id_only_match` firing is expected, not a fault — resolve it by importing manually in the
  Sonarr UI (Activity → Queue → the item → Manual Import), then check whether the same show keeps
  recurring; if so it may be worth a release-naming discussion rather than fighting the alert.
- `unsafe_extension` or `archive_not_extracted` firing means the fixer either isn't running, hit
  an error, or found a case its logic doesn't cover (e.g. the archive isn't a plain `.rar` set, or
  the flagged file isn't found where expected) — the log line explains which.
- A `reason` you don't recognise (`other`) means Sonarr surfaced a new warning message —
  `classify_queue_warning()` in `media-exporter.py` and the matching pattern in
  `sonarr-queue-fixer.sh` need a new branch.

## Where things live

- Fixer script + CronJob: `config/sonarr-queue-fixer.sh` / `applications/sonarr-queue-fixer.yml`
  in clincha/media
- Metric: `config/media-exporter.py`, `collect_sonarr_queue()` / `classify_queue_warning()`
- Rule: `kubernetes/flux/infrastructure/hawkfield/monitoring/alert-rules.yml`
- Routing: `kubernetes/flux/infrastructure/hawkfield/monitoring/alertmanager.yml`

## Known gap

The fixer only touches the two auto-fixable classes and only inspects the specific status
message text found on 2026-09-22. A Sonarr upgrade that reworded those messages would make both
the fixer and the metric stop matching silently — if `SonarrQueueStuck` starts firing constantly
with `reason="other"`, check the actual `statusMessages` text against both patterns first.
