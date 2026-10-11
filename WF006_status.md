# WF-006 Verification — CLOSED (Aug 27)

## Summary
Rule-based verification agent, no AI call. Checks required-field
completeness (`full_name`) + expiry date on `document_intelligence_results.
extracted_fields`. Writes two rows to `verification_results`
(DOCUMENT_AUTHENTICITY, DOCUMENT_EXPIRY), logs to `ai_agent_executions`,
and on PASSED/WARNING sets `documents.processing_status = VERIFIED`.

## Audit (before testing)
Full node-by-node field-mapping audit against real Supabase schema, per
standard procedure. Clean — no wrong-source-node bugs, no hardcoded
credentials, no stale `$json` references.

- `extracted_fields` — real JSONB column on `document_intelligence_results`, confirmed.
- `verification_results` insert fields — match schema exactly.
- `verification_type_enum` values used (`DOCUMENT_AUTHENTICITY`, `DOCUMENT_EXPIRY`) — valid.
- `verification_status_enum` values used (`PASSED`/`FAILED`) — valid.
- `documents.processing_status = 'VERIFIED'` — valid enum value.
- `ai_agent_executions.input_payload`/`output_payload` — JSONB, object literals fine.
- Minor style note (not a bug): `Insert Verification (Completeness)` uses
  implicit `$json` instead of explicit `$('Run Verification Rules')` like
  every other downstream node. Left as-is — flagged for consistency cleanup
  later, not urgent.

## Test 1 — PASSED branch (real data)
- Execution #554, succeeded in 4.887s.
- Input: `document_intelligence_result_id: aa4ccbad-89e4-4864-bf13-3dadb2b5fe7e`
  (real document, `full_name: "BHARGAVI. G"`, `expiry_date: null`).
- Traced upstream payload directly — fields were genuinely populated, not
  an empty-input false pass (bug #8 pattern check).
- Result: `completeness_status: PASSED`, `expiry_status: PASSED`,
  `overall_status: PASSED`. Routed to `Set Document VERIFIED` → STUB ping
  WF-007 → Respond Passed/Warning.
- DB-verified:
  - `verification_results`: 2 rows, both PASSED, correct messages.
  - `ai_agent_executions`: 1 row, VERIFICATION_AGENT, SUCCESS.
  - `documents.processing_status`: `VERIFIED`. ✅

## Test 2 — FAILED branch (synthetic expired doc)
- Inserted a throwaway `document_intelligence_results` row (id
  `15878ec0-77b6-40fe-a822-aa5bc5206bb2`) on top of a real, unused
  document/version/OCR chain (`document_id 63131182-...`, same
  application `84397920-...`), with `expiry_date: "2020-01-01"`.
- Execution #555, succeeded in 2.636s.
- Result: `completeness_status: PASSED`, `expiry_status: FAILED`
  (`"Document expired on 2020-01-01."`), `overall_status: FAILED`. Routed
  to STUB Trigger Reminder Agent → Respond Failed, with correct `reasons`
  array.
- DB-verified:
  - `verification_results`: 2 rows — AUTHENTICITY PASSED, EXPIRY FAILED.
  - `documents.processing_status`: stayed `OCR_COMPLETED` (correctly
    **not** touched — VERIFIED only fires on PASSED/WARNING branch). ✅
- Test row + its `verification_results`/`ai_agent_executions` rows deleted
  after verification. Real document `63131182-...` left untouched.

## Known Gaps, Logged Not Blocking
- `processing_time_ms` / `execution_duration_ms` / `completed_at` on
  `ai_agent_executions` are null. Same class of gap as WF-004/WF-005.
  Same fix (dedicated `Compute Duration` node) applies. Not yet applied
  anywhere in the pipeline — worth doing as one batch fix across all
  workflows rather than one at a time.
- `verification_type_enum` has no dedicated "completeness" type;
  `DOCUMENT_AUTHENTICITY` is reused for the full_name check. Flagged in
  the node's own `notes` field, intentional, not blocking.

## STUB Nodes Still Open (unchanged, expected)
- `STUB Ping Cross Validation (TODO wire WF-007)`
- `STUB Trigger Reminder Agent (TODO wire WF-009)`
Both fired correctly as placeholders in both test runs. Do not wire live
until WF-007 and WF-009 are independently closed (same rule WF-005
followed for WF-006).

## Next Up
**WF-007 Cross Validation** — built, not tested. Same audit-first
discipline: open every node, trace every field mapping to its real source
node, confirm exact field names via that node's actual OUTPUT before
wiring or trusting. WF-007 self-gates on `document_checklists` /
`documents.processing_status = 'VERIFIED'` per-application readiness — needs
an application with ALL required checklist docs actually VERIFIED to
exercise the "ready" path, plus a partial-completion case to exercise the
WAITING self-gate. Confirm real test data availability (or build it) before
starting.
