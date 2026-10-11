# WF-001 Conversation Manager — Status

**Status: DONE. Document-intake path confirmed via real Telegram-triggered
execution, DB-verified.**

## Verified Working
WF-001 now owns document intake end-to-end by itself — validation, upload,
DB insert, checklist update, event publish, and handoff to WF-004. Confirmed
via real Telegram-triggered execution: `documents` row created,
`document_checklists.status` flips to `RECEIVED`,
`Execute Workflow: WF-004` fires with a correctly-shaped payload.

## Major Architecture Decision Made
**WF-003 is retired from the live pipeline.** WF-001 absorbed document
intake fully. WF-003 remains as a standalone, already-DB-verified build for
reference only — nothing calls it live anymore. This was a deliberate
simplification, not a bug fix. Do not reintroduce a second intake path.

## Bugs Found & Fixed

### 1. Conversation History token blowout
`AI Agent` node hit OpenAI's 30,000 TPM rate limit on gpt-4.1 because
`Conversation History` pulled unbounded rows (208+ in test data). Fixed with
a new Code node `Recent Conversation History` (sorts by `created_at` DESC,
slices to 15) inserted between `Conversation History` and
`Build Conversation Context`. Updated `Build Conversation Context`'s code to
reference `$('Recent Conversation History')` instead of the raw Supabase
node.

### 2. Document intake branch was dead-ended
WF-001 had a complete inline document-handling branch (`Download Telegram
File → Upload to Supabase Storage → Insert Document Record → Update
Checklist Status → Publish Document Uploaded Event`) that never went
anywhere. Wired it live:
- `Validate Document` (Code node) — checks mime type / size, right after
  `Download Telegram File`.
- `IF Valid?` — routes to upload chain (true) or `Set Status Failed`
  (false).
- `Set Status Failed` — inserts a `documents` row with
  `processing_status = FAILED`. **Known gap:** `documents` has no
  `error_message` column — validation reasons are not persisted anywhere
  yet.
- `Prepare OCR Payload` (Code node) — reshapes the item into
  `{ document_id, storage_path, mime_type, application_id }` before handoff.
  Required because WF-004's trigger has no defined input schema and just
  forwards whatever arrives — without this reshape, WF-004 received raw
  `workflow_events` data and errored "document_id missing from input
  payload."
- `Execute Workflow: WF-004 OCR Agent` — wired live, replacing the old dead
  end after `Publish Document Uploaded Event`.

### 3. `Upload to Supabase Storage` — multiple bugs
- Was using the `anon`/`publishable` key instead of `service_role` — caused
  silent storage-policy rejections (generic 400s). Fixed with the real
  service_role key. **Tech debt, not fixed:** still hardcoded in headers,
  should move to a proper HTTP Header Auth credential.
- URL field had a stray leading `=` while the Fixed/Expression toggle was on
  Fixed — sent literally as part of the string, causing "URL must start with
  http/https." Fixed by switching the field to Expression mode.
- Filenames with spaces (e.g. `Bhargav License.pdf`) needed
  `encodeURIComponent()` around the filename segment of the storage path —
  added.
- 409 Duplicate/KeyAlreadyExists on retries — added `x-upsert: true` header
  so repeat test uploads overwrite instead of erroring.

## Bug Pattern Confirmed (Recurring Project-Wide)
Stale `$json` after an intermediate node reassigns it — always trace to
source with `$('Node Name').item.json.field`. Hit WF-001's IF node (and
recurred in WF-002 through WF-005). First suspect on any "wrong branch
taken" or "field is null/undefined" bug.

## Known Gaps, Logged Not Blocking
- `documents` table has no `error_message` column — `Set Status Failed`
  cannot persist validation failure reasons anywhere. Low priority, revisit
  when building broker-facing error visibility (WF-010 territory).
- Borrower uploading a document type NOT on their checklist (e.g. a licence
  when none was requested) is currently silently logged to
  `Log Unmatched Document` with no correction message sent back, despite a
  "received and processing" reply template existing. Real product gap —
  flagged for WF-009/WF-010 design.
- `Upload to Supabase Storage` still has the service_role key hardcoded in
  headers rather than a proper credential — works, not production-clean.
- `document_versions.file_hash` fallback is a hash of `storage_path`, not
  real file bytes. Low priority, inherited pattern across WF-001/WF-004.

## Process Notes
- `document_checklists` has a `UNIQUE(application_id, document_type_id)`
  constraint — cannot insert a second checklist row for the same doc type on
  the same application. To re-test a document upload, RESET the existing row
  instead of inserting a new one:
  ```sql
  UPDATE document_checklists
  SET status = 'REQUESTED', received_at = NULL, verified_at = NULL, updated_at = now()
  WHERE id = 'abb7cac8-1aa3-4627-931b-da9a16d1b39b';
  ```
  Standard re-test reset command for the driver's-licence checklist row on
  test application `84397920-5b40-42ca-95e2-e5e47db8c1cd`.
- Same Save-AND-Publish discipline enforced — verify every result via direct
  DB query, not the n8n green checkmark. Green ≠ correct.

## Next Up
No blocking work remains on WF-001 itself. Downstream: WF-004 PDF path is
now also closed (see `WF004_status.md`). Focus shifts to WF-005 COMPLETED
branch testing next.
