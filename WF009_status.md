# WF-009 Reminder Agent — CLOSED (Aug 27)

## Summary
Generic, source-agnostic borrower-notification agent. No prior repo spec
existed — designed to serve every reminder need identified so far from a
single simple contract: `{ application_id, document_id?, reasons?: string[],
source? }`.

- Looks up the application's primary borrower and their linked Telegram
  `chat_id` (real channel currently supported; WhatsApp is still a
  passthrough placeholder project-wide, per WF-001).
- If linked: composes a plain-language reminder from `reasons`, sends via
  Telegram, logs to `messages` (same schema/pattern as WF-001's own
  outbound messages), and — if a `document_id` was supplied — resets that
  document's `document_checklists` row to `REQUESTED` (single
  `UPDATE ... FROM documents` query, safely no-ops when `document_id` is
  null, no branching needed).
- If not linked: logs the skip as a `SUCCESS` (the agent correctly decided
  not to send — that's not a failure) with the reason in `error_message`,
  no message sent.
- Logs every run to `ai_agent_executions` regardless of outcome.

This single agent now covers both real gaps identified earlier: the
expired-passport re-request (WF-006's existing stub payload shape) and
cross-validation mismatch follow-up (WF-007's stub). Same contract works
for both — caller just supplies different `reasons` and `source`.

## Bugs Found and Fixed (2, both real, both caught before shipping)

**1. Wrong Telegram credential auto-assigned.**
`create_workflow_from_code` matched the `Send Telegram Message` node to
`"Telegram account"` instead of the explicitly requested
`"Telegram - Mortgage"` (the credential every other Telegram-sending
workflow in this project, i.e. WF-001, actually uses) — despite passing
the exact credential name. Caught by checking `autoAssignedCredentials` in
the creation response rather than assuming the name match worked. Fixed
with an explicit `setNodeCredential` operation using the real credential ID
(`YZqLAADMT51H9lJA`) confirmed via `list_credentials` beforehand.

**2. Invalid `execution_status` value against an undocumented CHECK constraint.**
`Log Agent Execution (Skipped)` originally wrote `execution_status:
'SKIPPED'`. `ai_agent_executions` has a CHECK constraint
(`chk_execution_status`) that only permits `RUNNING`, `SUCCESS`, `FAILED`,
`CANCELLED`, `TIMEOUT` — not visible in the migration file, only found by
reading `pg_constraint` directly after the insert failed on the first real
test. The agent's own behavior was correct (it made the right decision not
to send); `SKIPPED` was never a valid outcome value in this schema's
vocabulary. Fixed by using `execution_status: 'SUCCESS'` with the skip
reason moved to `output_payload.result` and kept in `error_message`.

**Also caught, unrelated to either bug above:** `Send Telegram Message`'s
`resource`/`operation` discriminators silently disappeared from the node's
parameters between the first successful test and a later
`get_workflow_details` check (root cause not fully identified — possibly a
side effect of the credential-fix operation touching the node). Static
validation flagged it (`Missing discriminator "parameters.resource"`)
before it could cause a silent failure; restored explicitly via
`updateNodeParameters` with the full correct parameter set. **Process note:**
after any `setNodeCredential` or partial `updateNodeParameters` call, re-check
the full node JSON via `get_workflow_details` before trusting the change was
isolated to only what you intended to touch.

## Test 1 — SENT (real send, real borrower)
- Execution #593, application `f0ec4f3c-...`, document `199dd45a-...`
  (the genuinely expired passport).
- Real Telegram message sent from the correct bot (`matadu_ai_bot`,
  confirming the credential fix), confirmed delivered by the borrower's own
  screenshot of the chat.
- DB-verified: `messages` row correct (`delivery_status: DELIVERED`,
  `external_message_id` populated from the real Telegram response).
  `document_checklists` row for the passport correctly reset to
  `REQUESTED`, `received_at`/`verified_at` cleared — this is a genuine,
  real production fix, not just a test artifact: this application's
  passport slot is now actually open for a real resupply.

## Test 2 — SKIPPED (no linked channel)
- Execution #595, application `84397920-...` (real application, primary
  borrower has no `telegram_chat_id` on file — found via direct query, not
  fabricated).
- Correctly took the false branch. Execution's `lastNodeExecuted:
  "Respond Skipped"` and DB both confirm — note the n8n canvas visualization
  showed stale/misleading branch highlighting on this run; the actual
  execution data (via `get_execution`) and the DB are what were trusted, not
  the screenshot's highlighting. Worth remembering for future visual
  execution checks: canvas highlighting can lag or mis-render, always
  pull the real execution JSON before concluding a branch didn't fire.
- DB-verified: `ai_agent_executions` row — `execution_status: SUCCESS`,
  `error_message` contains the real skip reason, `trigger_source: TEST`.

## Known Gaps, Logged Not Blocking
- WhatsApp channel is not implemented (project-wide limitation inherited
  from WF-001, "passthrough today" per that workflow's own code comment).
  WF-009 only supports Telegram for now — a borrower whose
  `preferred_channel` is WhatsApp but who also has a linked Telegram
  `chat_id` will still get a Telegram message (this is what happened for
  both applications tested today — both borrowers had `preferred_channel:
  WHATSAPP` but a real Telegram link).
- No retry/backoff if the Telegram send itself fails (e.g. bot blocked by
  user). `delivery_status: FAILED` would be logged correctly, but nothing
  currently re-attempts or escalates to a broker. Low priority for MVP.
- Same `execution_duration_ms`/`completed_at` null gap as every other
  workflow in this pipeline.
- Data quality note, not a WF-009 bug: two different `borrowers` rows in
  this test dataset (`22b42868-...` "Test Borrower" and the real onboarded
  borrower) appear to share the same `telegram_chat_id`
  (`6569431491`) — both resolve to the same physical Telegram account.
  Harmless for testing (this is why the SENT test's reminder appeared in
  the real borrower's chat), but worth a data-integrity pass before this
  goes anywhere near production: `telegram_chat_id` has a unique index
  (`idx_borrowers_telegram_chat_id`) per the WF-001 migration, so this
  apparent duplication needs verifying — possibly one of the two borrower
  rows is stale test data that should be cleaned up.

## STUB Wiring Not Yet Done
WF-006 and WF-007 both still have their `STUB Trigger Reminder Agent`
placeholders unwired to this real workflow. Same rule as always: don't wire
live until independently confirmed clean — done here, so this is now safe
to wire. Not wired yet this session; next session's first move on this
front should be wiring both.

## Next Up
1. **Wire WF-006 → WF-009 and WF-007 → WF-009 live**, replacing both STUB
   nodes with real Execute Sub-workflow calls, same pattern as every other
   live-wiring done this session. WF-006's stub already defines the exact
   payload shape WF-009 expects (`{ document_id, application_id, reasons }`);
   WF-007's stub will need `{ application_id, reasons }` built from its own
   `cross_validation_results` MISMATCH rows at wiring time (same pattern
   WF-008 already uses to build its own decision reason).
2. **WF-010 Broker Notification** — not started, no repo spec. Needed once
   WF-008's `STUB Trigger Broker Notification` stops stubbing.
3. Password-collection flow for WF-004's password-protected-PDF gap still
   has no borrower-facing trigger — WF-009 now has everything needed to
   send that specific reminder (`reasons: ["This document is
   password-protected. Please reply with the password so we can process
   it."]`), just needs something to detect the password-protected failure
   in WF-004 and call WF-009. Not built this session — WF-004 still just
   fails outright with no notification on that path.
