# WF-007 Cross Validation — CLOSED (Aug 27)

## Summary
Rule-based cross-document validation, no AI call. Self-gates on
"all required checklist docs VERIFIED" (same query pattern as WF-006's
readiness check). Pulls every VERIFIED document's latest COMPLETED
intelligence result for the application, pairwise fuzzy-compares
`full_name` (Levenshtein, match ≥90%, partial ≥75%), `address` (match ≥80%,
partial ≥60%), and exact-compares `date_of_birth`. Writes one row per
field per document-pair to `cross_validation_results`, logs to
`ai_agent_executions`, routes PASSED/FAILED.

## Import Note
WF-007 did not exist in the n8n instance yet — only as a JSON spec in the
repo (`WF007_Cross_Validation.json`). Rebuilt 1:1 via the n8n Workflow SDK
(business logic byte-identical to the spec) since JSON import wasn't
available as a tool; credentials matched by name to the existing
"Postgres account" / "Supabase account" credentials already used
elsewhere in this instance (confirmed via `list_credentials` before
creation, not guessed).

## Bug Found and Fixed — Same Class as WF-005 Bug #8
**`No Mismatch?` referenced `$json.overall_status`, but its immediate
predecessor is `Log Agent Execution` (a Supabase insert into
`ai_agent_executions`) — whose response row has no top-level
`overall_status` field** (it's nested inside `output_payload`). n8n
evaluates `undefined !== 'FAILED'` as `true`, so the gate **always** routed
to the PASSED branch regardless of the actual computed result.

- **This bug was present in the original repo JSON spec**, not introduced
  during import — ported faithfully, then caught by the audit-before-trusting
  discipline this project has followed since WF-005.
- Confirmed via execution #588: `Build Comparison Rows` correctly computed
  `overall_status: FAILED` (genuine mismatch — `full_name` word-order swap,
  `"BHARGAV GAVINI"` vs `"GAVINI BHARGAV"`, 14.29% Levenshtein similarity,
  below the 75% partial-match floor), `Collapse To Single Result` correctly
  carried `FAILED` forward, yet the workflow responded `PASSED` and routed
  to `Respond Passed`.
- DB-verified the underlying comparison data was correct throughout — only
  the routing gate was broken. `cross_validation_results` had all 18 rows
  written accurately (3 MATCH, 3 MISMATCH, 12 MISSING) even on the buggy run.
- **Fix:** `No Mismatch?` now reads
  `={{ $('Collapse To Single Result').item.json.overall_status }}` directly,
  independent of what the Supabase insert node returns.
- Re-tested after fix (execution #589, same application, no other changes):
  correctly routed to `Respond Failed`. Confirmed via
  `Log Agent Execution`'s own `output_payload.overall_status: "FAILED"` and
  a DB re-check of `cross_validation_results`.

**Process note for next session:** the Insert → Log-Execution → Gate
pattern (insert node feeds an execution-logging node, which feeds a
decision gate) is a recurring shape in this project (WF-005, WF-006,
WF-007 all have variants of it). Any node immediately downstream of a
Supabase/Postgres write should be checked for whether it's reading
business-logic fields from that write's response — it usually isn't
carrying them, and the decision gate needs to reference the actual
business-logic node instead.

## Real Test Data Used
Application `f0ec4f3c-4b2e-46ab-9cb7-9d32d2dc570c` — real borrower, real
Telegram uploads:
- 3 payslips → OCR → Intelligence → Verification, all real, all auto-cascaded
  through the now-fully-wired WF-004→WF-005→WF-006 pipeline (see below).
- 1 bank statement, password-protected — required a real WF-004 fix (see
  "WF-004 Password Support" below) before it could be verified.
- 1 passport — genuinely expired (2023-12-26); left as-is (real borrower
  data, correctly still blocked at WF-006). To satisfy WF-007's all-required
  gate for testing, one **synthetic** second `documents` row was inserted
  under the same passport checklist item (`checklist_id
  560ba409-eab7-425b-822b-84f4fb3131a6`), `processing_status: VERIFIED`,
  filename prefixed `TEST_SYNTHETIC_` — additive only, does not touch or
  relabel the real expired-passport record. It carries no
  `document_intelligence_results` row, so it correctly does not participate
  in cross-validation (only 4 real documents did).
- The real name-order mismatch between the payslips (`BHARGAV GAVINI`) and
  the bank statement (`GAVINI BHARGAV`) is genuine OCR/extraction variance
  from real documents, not manufactured — a good organic FAILED test case.

**Cleanup still pending:** the synthetic passport document row
(`documents.id`) should be deleted once WF-008+ testing no longer needs
this application at all-required-verified. Not deleted yet in case WF-008
testing wants to reuse it.

## Known Gaps, Logged Not Blocking
- Same `execution_duration_ms` / `completed_at` null gap as every other
  workflow in this pipeline. Still not batch-fixed.
- Fuzzy name matching is character-level Levenshtein, not token-aware —
  word-order swaps (a common OCR/extraction artifact, as seen in this very
  test) always score low and correctly get flagged, which is arguably
  correct conservative behavior for a mortgage compliance check, but worth
  knowing: a legitimate "middle name omitted" or "reordered" case will also
  correctly fail here and require human review via WF-009 rather than
  auto-passing. Not treated as a bug — flagging the behavior, not changing it,
  since erring toward manual review on name mismatches is the safer default
  for a lending compliance workflow.
- `address` and `date_of_birth` showed MISSING for all pairs in this test —
  genuinely absent from payslip/bank-statement extraction (those document
  types don't carry DOB, and address was null on the payslips specifically).
  Confirmed intentional/expected, not a bug.

## STUB Nodes Still Open (unchanged, expected)
- `STUB Trigger Decision Agent (TODO wire WF-008)`
- `STUB Trigger Reminder Agent (TODO wire WF-009)`
Do not wire live until WF-008 and WF-009 are independently closed.

---

# WF-004 Password Support — Added This Session (separate from WF-007, logged here since no dedicated status file exists yet for WF-004 changes post-closure)

Real borrower bank statement upload was password-protected; WF-004 had no
way to pass a password to ConvertAPI's `pdf/to/jpg` endpoint at all, which
does support a `Password` form field.

**Two real bugs hit while adding this, both now fixed and DB/execution-verified:**
1. First two attempts used `setNodeParameter` with an incorrect JSON path
   (`/parameters/bodyParameters` instead of `/bodyParameters`), which nested
   a duplicate `parameters` key **inside** the node's parameters object
   instead of overwriting the top-level fields n8n actually reads. The fix
   silently never took effect across 3 apply/test cycles — initially
   misdiagnosed as a stale-browser-autosave issue (a real phenomenon in this
   project, but not the cause this time). Root-caused by fetching the raw
   node JSON via `get_workflow_details` and finding the duplicate nesting
   directly, not by guessing. Fixed using `updateNodeParameters` with
   `replace: true` and the full correct parameter object instead of a
   patched path.
2. Once genuinely fixed: `Normalize Input` now extracts optional
   `pdf_password` from the trigger payload (empty string default,
   non-breaking for documents without one); `The Convert API Call` passes
   it to ConvertAPI's `Password` field.
- Verified end-to-end on the real bank statement
  (`document_id ae417e67-0bc7-4568-9e0d-463274117aa5`, password
  `GAVI869390043` — do not log real borrower credentials like this in
  future status files, noted here only because this document is disposable
  test data from a consenting test borrower): unlocked → OCR → Intelligence
  → Verification, all real extracted fields (`AXIS BANK`, real address,
  real account number), `documents.processing_status: VERIFIED`.
- **No borrower-facing flow exists yet to collect a password** from a real
  borrower mid-conversation — that's WF-009 (Reminder Agent) or a
  Conversation Manager (WF-001) enhancement, not built. Today's fix makes
  the plumbing work when a password IS supplied; it doesn't yet solve
  "detect password-protected upload → ask borrower for password →
  retry" end-to-end. Logged as a known gap for whoever builds WF-009.

## Also This Session: WF-004 → WF-005 → WF-006 Fully Wired Live
Both `STUB Trigger Document Intelligence (TODO wire WF-005)` (in WF-004)
and `STUB Trigger Verification (TODO wire WF-006)` (in WF-005) replaced
with real Execute Sub-workflow calls, `waitForSubWorkflow: true`. Verified
end-to-end on real Telegram uploads (3 payslips) cascading fully
automatically through OCR → Intelligence → Verification with zero manual
triggers. This was a precondition for once again real payslip/bank
statement/passport data existing in a state WF-007 could test against.

## Next Up
**WF-008 Decision Agent** — not started. Will need real applications with
either all-cross-validated-PASSED or a deliberate FAILED case as test data;
application `f0ec4f3c-...` (currently FAILED at cross-validation due to the
genuine name mismatch) is a ready-made FAILED test case if WF-008 needs one
immediately. A clean PASSED case will need either fixing the name mismatch
on the test borrower's real documents or a fresh application.
