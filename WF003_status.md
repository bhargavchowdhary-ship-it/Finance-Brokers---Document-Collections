# WF-003 Document Intake — Status

**Status: CLOSED. Both branches (success + failure) verified via DB query on Published version.**

## Verified Working
8-node linear flow, branches on file validation (mime type / size / password-protected).
Triggered via `Execute Workflow` (currently manual test trigger — real wiring from
WF-001 is a documented, deliberate stub, see below). Two clean runs on Published
version, confirmed via `documents.processing_status` and `ai_agent_executions`
DB rows, not just the n8n "Succeeded" badge.

- **Success path:** valid `image/jpeg`, 211KB, not password-protected →
  `documents.processing_status = PROCESSING`, `ai_agent_executions` row written
  (`agent_name = DOCUMENT_INTAKE_AGENT`, `execution_status = SUCCESS`,
  `application_id` correctly resolved).
- **Failure path:** `application/octet-stream`, 0 bytes →
  `documents.processing_status = FAILED`, `error_message = "unsupported_file_type,
  empty_file"` (both reasons captured in the array, not just the first match).

## Bug Found & Fixed This Session
Both `Log Agent Execution` nodes (success and failure branches) referenced
`$json.application_id`. By that point in the chain, `$json` was the output of
a `Supabase update` node (`Set Status Processing` / `Set Status Failed`) —
which returns the updated `documents` row, and `documents` has no
`application_id` column (it's reached only via `checklist_id →
document_checklists → loan_applications`). Same shape of bug as WF-002's
`agent_code` mismatch: a stale/incorrect field reference after an intermediate
node reassigns `$json`, silently producing a null/wrong value instead of an
error.

**Fix:** Both nodes now reference `$('Validate Document').item.json.application_id`
explicitly — the node earlier in the chain that actually resolved it via the
checklist → application lookup.

## Known, Deliberate Gap — Not a Bug
`STUB Trigger OCR Agent` is a placeholder `Set` node, not a real
`Execute Workflow` call to WF-004. This is intentional — same pattern as
WF-002's original stubs. **Do not wire it live until WF-004 is independently
confirmed clean.** The exact payload contract is documented in the stub node's
note field: `{ document_id, storage_path, mime_type, application_id }`.

## Process Notes
- Same Save-AND-Publish discipline as WF-002 — confirmed the first test run
  landed on Autosave/draft, re-ran after Publish before treating it as valid.
- Real `documents` row used for success test:
  `63131182-82ad-481d-a780-ee82b9bd4ea8` (checklist_id
  `c2e49e6c-7e7c-489b-abe4-df43bfc890c3`, application_id
  `84397920-5b40-42ca-95e2-e5e47db8c1cd`).
- Throwaway row used for failure test: `12bd253d-cf7b-4a97-8943-afdc8023ba50`
  (same checklist_id — safe to delete, isolated test data).

## Next Up
WF-004 OCR Agent — import, fix the hardcoded `YOUR_SUPABASE_SECRET_KEY`
placeholder in `Download Document` (swap for real service role key), Save +
Publish, test with the same verified document above. Contract WF-003 →
WF-004: `{ document_id, storage_path, mime_type, application_id }`.
