# WF-005 Document Intelligence — Status

**Status: FULLY CLOSED. Both FAILED and COMPLETED branches verified via DB
query on Published version (ID#553, Aug 27).**

## Verified Working
GPT-4.1 extraction against universal schema (`full_name`, `date_of_birth`, `address`,
`document_number`, `expiry_date`, `issuer`), branching on `Extraction Succeeded?`.
Both branches now confirmed on real executions, DB-verified — not just the n8n
green checkmark.

**COMPLETED branch (closed Aug 27, real ID document):**
- `document_intelligence_results`: `intelligence_status = 'COMPLETED'`,
  `document_id`/`ocr_result_id` correctly linked (real UUIDs, not null),
  `extracted_fields` populated with real values —
  `full_name: "BHARGAVI. G"`, `address: "D.NO: 26-203, H P C COLONY, CHINA
  GANJIMAKA, VISAKHAPATNAM"`, `document_number: "AP03120110085692"`,
  `issuer: "RTA-VISAKH-"`, `confidence_score: 66.67`. `date_of_birth` and
  `expiry_date` correctly null — genuinely absent from this document type,
  not a bug.
- `ai_agent_executions` (`agent_name = DOCUMENT_INTELLIGENCE_AGENT`):
  `execution_status = 'SUCCESS'`, `total_tokens = 310`, real
  `input_payload`/`output_payload` captured.
- Test document: `document_id c83e0dc9-e6f2-4fba-a6e3-02839c409396`,
  `ocr_result_id ff1adf58-65e9-4b8f-b226-6fc559146564` (same real driving
  licence that closed WF-004's PDF path the day before).

**FAILED branch (closed prior session):** see below, unchanged.

- `document_versions`: row created, `version_number = 1`, `file_hash` populated
  (pure-JS fallback hash of `storage_path`, not real file bytes — known low-priority
  gap carried from WF-001).
- `documents.processing_status`: still `OCR_COMPLETED` — no dedicated
  "intelligence completed" enum value exists yet. Confirmed intentional, not a bug.

## Bugs Found & Fixed (Prior Session — FAILED branch, #1–7)
See prior entries below (Code node `crypto` module, `$json`-staleness,
trailing whitespace on UUIDs, schema mismatch on `is_success`/`reasons`
columns, `Get many rows` zero-item halt, version-number collision,
`ocr_result_id` unique constraint). Unchanged, still accurate.

## Bugs Found & Fixed This Session (Aug 27 — COMPLETED branch)

### 8. GPT extraction prompt referenced the wrong source node for ALL THREE variables
`Call GPT-4.1 Extraction`'s user-message template pulled `document_type_code`,
`document_type_category`, and `raw_text` all from `$('Prepare Version
Payload')` — a node that only carries version metadata (`id`, `document_id`,
`version_number`, `storage_path`, `file_hash`, etc.), none of these three
fields. Every extraction ran against a prompt containing three literal
`"undefined"` strings, including an empty OCR text block — so GPT correctly
returned all nulls every time, masquerading as a "successful" FAILED-branch
result. Root cause was invisible without opening the raw request body (the
node's own INPUT/OUTPUT panels don't show the interpolated string, only the
final API response).

Fixed by correcting all three references to their real source nodes and
field names (confirmed field names via each node's actual OUTPUT, not
assumed):
```
content: `Document type: ${$('Get Document Type').item.json.code} (${$('Get Document Type').item.json.category})\n\nOCR TEXT:\n${$('Get OCR Result').item.json.raw_text}`
```
(`document_type_code`/`document_type_category` don't exist on
`Get Document Type` — real fields are `code` and `category`.)

**This is the same bug family as #2, but the most severe instance yet** — it
didn't error, it silently produced a plausible-looking FAILED result on
every run, and the prior session's own status file initially read this as
"correct behavior since the test doc was invalid" (which was independently
also true, masking this bug for a full session).

### 9. `Insert Intelligence Result (COMPLETED)` — 2 of 9 fields wrong-node
`document_id` and `ocr_result_id` fields both used bare `{{$json.field}}`,
resolving to `Parse Response`'s output (which carries neither field) →
`undefined` → Postgres correctly rejected with `null value in column
"document_id" ... violates not-null constraint`. Fixed both to explicit
source references: `{{$('Normalize Input').item.json.document_id}}` and
`{{$('Normalize Input').item.json.ocr_result_id}}` (both present on the
original trigger payload). Audited remaining 7 fields in the same pass —
all correct except `processing_time_ms` (see Known Gaps, not a wiring bug,
genuinely null upstream).

## Bug Pattern Confirmed (Escalated Severity)
**Wrong-source-node references can fail silently as plausible business
logic, not just as errors.** Bug #8 didn't throw — it produced a `FAILED`
result with `reasons: ["no_fields_extracted"]` that looked like a correct
rejection of a bad document, when the real document was fine and the prompt
was empty. Any time a branch's outcome depends on model/API judgment (not a
hard validation rule), verify the actual request payload sent, not just the
response received, before trusting a result — especially before trusting a
"correctly failed" result as proof of anything.

## Known, Deliberate Gap — Not a Bug
`STUB Trigger Verification (TODO wire WF-006)` remains a placeholder. Do not
wire it live until WF-006 is independently confirmed clean.

## Known Gaps, Logged Not Blocking
- `processing_time_ms` on `document_intelligence_results` is `null` —
  confirmed genuinely null upstream on `Parse Response`'s own output, not a
  field-mapping bug. Same class of gap as WF-005's `execution_duration_ms`
  gap noted previously; same fix pattern (dedicated `Compute Duration` node,
  as used in WF-004) would resolve both. Not applied, not blocking.
- `document_versions.file_hash` remains a hash of `storage_path`, not real file
  bytes (inherited from WF-001/WF-004 pattern). Low priority.
- `documents.processing_status` has no dedicated "intelligence completed" enum
  value — stays at `OCR_COMPLETED` through this stage. Confirmed intentional.

## Process Notes
- Confirmed (again) that "Succeeded" + fast runtime is not proof of
  correctness. Bug #8 is the sharpest example project-wide so far: an entire
  prior session's FAILED-branch closure was technically DB-verified
  correctly, yet still built on a broken prompt that happened to produce a
  defensible-looking null result.
- Retest cleanup commands used this session (standard pattern going
  forward — delete both tables, in this order, before any WF-005 retry):
  ```sql
  DELETE FROM document_intelligence_results WHERE ocr_result_id = '<id>';
  DELETE FROM document_versions WHERE document_id = '<id>';
  ```

## Next Up
1. **WF-006 Verification** — rule-based only, no AI call. Checks required-field
   completeness (`full_name`) + expiry date. Audit every node for the
   `$json`-staleness / wrong-source-node pattern proactively BEFORE testing
   (9 confirmed occurrences across WF-002 through WF-005 now) — trace every
   field mapping to its real source node and confirm exact field names via
   that node's actual OUTPUT before wiring, don't assume field names from
   memory or from similarly-named fields elsewhere. Confirm no hardcoded
   credential placeholders, Save + Publish, test against today's real
   COMPLETED intelligence result: `document_id
   c83e0dc9-e6f2-4fba-a6e3-02839c409396`.
2. Once WF-006 closes, WF-007 Cross Validation is next, same audit-first
   discipline.
