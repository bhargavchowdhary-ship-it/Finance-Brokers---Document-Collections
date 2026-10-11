# WF-010 Broker Notification — CLOSED (Aug 27), Updated (Aug 30)

## Summary
No prior repo spec existed. Notifies the broker by email on two decision
outcomes now (originally just one — see Update below). Payload:
`{ application_id }`.

- Queries broker, application, borrower, and latest `decision_results` row
  for the application in one join.
- **As of Aug 30, composes a different email depending on
  `final_decision`:**
  - `APPROVED` → subject `"Application {number} ready for review —
    {borrower}"`, framed as "completed collection, verification, and
    cross-validation... ready for your review and submission."
  - `MANUAL_REVIEW` → subject `"Action needed: Application {number} —
    {borrower}"`, framed as "needs your review... cross-validation found a
    discrepancy... please review the flagged documents and decide how to
    proceed."
- Sends via Gmail (`Gmail account` credential).
- Logs to `messages` (channel `EMAIL`, `receiver_type: BROKER`) and
  `ai_agent_executions`.

Still deliberately does not handle `MORE_DOCUMENTS_REQUIRED` — that
decision is a "still waiting" state, not something a broker needs emailed
about. WF-008 (the caller) enforces this by only ever invoking WF-010 on
`APPROVED` or `MANUAL_REVIEW`.

## Update — Aug 30: MANUAL_REVIEW Email Variant
Closed the gap this file itself originally logged: "Only handles the
APPROVED path... a broker has no way to know an application needs their
attention unless they check `decision_results` directly." `Compose Broker
Email` now branches subject/headline text by `ctx.final_decision`
(already available from the existing `Get Application Decision Context`
query — no new data plumbing needed). WF-008 was updated in parallel to
actually call WF-010 on the `MANUAL_REVIEW` path (see `WF008_status.md`
for that side of the change).

### Test — real send, real MANUAL_REVIEW data
- Triggered via WF-008's new `Needs Broker Attention?` → `Trigger WF-010
  Broker Notification (Manual Review)` path, using a temporarily
  re-broken real name-match on application `f0ec4f3c-...` (see
  `WF008_status.md` for the full test setup/teardown).
- DB-verified: `messages` row — `delivery_status: SENT`, `message_text`
  contains the new "Action needed" framing, correctly includes the real
  4-mismatch decision reason, ends with "Please review the flagged
  documents and decide how to proceed." (the MANUAL_REVIEW-specific
  closing line, distinct from the APPROVED closing line).
- No bugs found in this change — clean, matching WF-010's original
  first-pass track record from Aug 27.

## Test — real send, real data (original, Aug 27)
- Execution #596, application `f0ec4f3c-...`, real `APPROVED` decision.
- Real Gmail send accepted, real message ID, correct composed content
  (borrower name, application number, loan type, formatted currency
  amount, decision, decision reason).
- DB-verified: `messages` and `ai_agent_executions` rows both correct.

## Known Gaps, Logged Not Blocking
- Same `execution_duration_ms`/`completed_at` null gap as every other
  workflow in this pipeline.
- No retry/backoff if the Gmail send fails outright. Not tested — real
  credential has been healthy throughout.
- `MORE_DOCUMENTS_REQUIRED` remains entirely unhandled by design (see
  above) — if that ever needs to change, it's a scope decision for a
  future session, not an oversight.

## STUB Nodes Still Open
None. WF-010 has no stubs — it's a terminal node in the pipeline (nothing
currently calls further downstream from it, by design).

## Repo Note
`WF010_Broker_Notification.json` should be re-exported from n8n and
re-uploaded — the version currently in the repo (if any) predates the
Aug 30 `Compose Broker Email` branching logic.

## Next Up
Nothing outstanding specific to WF-010. See `WF008_status.md` for the one
remaining related gap (`MORE_DOCUMENTS_REQUIRED` real-data test).
