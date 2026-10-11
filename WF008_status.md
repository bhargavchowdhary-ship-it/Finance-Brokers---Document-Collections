# WF-008 Decision Agent — CLOSED (Aug 27), Updated (Aug 30)

## Summary
Rule-based decision gate, no AI call. No prior repo spec existed — built
from scratch per explicit scope: "if WF-007 PASSED → go-ahead for broker,
if FAILED → block + reason." Independently re-queries the latest
`CROSS_VALIDATION_AGENT` execution for the application rather than
blindly trusting it was only invoked after a genuine PASSED result — same
audit-first discipline used throughout this project.

- `overall_status = 'PASSED'` → `final_decision: APPROVED`, confidence 100,
  writes to `decision_results`, triggers WF-010 (Broker Notification).
- `overall_status = 'FAILED'` → pulls real `MISMATCH` rows from
  `cross_validation_results`, builds a human-readable `decision_reason`,
  `final_decision: MANUAL_REVIEW`. **As of Aug 30, this now also triggers
  WF-010** (see below) — a broker is notified when their judgment is
  needed, not just when an application is ready to submit.
- No completed cross-validation record found at all →
  `final_decision: MORE_DOCUMENTS_REQUIRED`. **Deliberately does not
  trigger WF-010** — this is a "still waiting" state, not an actionable
  broker event, same category as the self-gating WAITING states elsewhere
  in the pipeline. A broker doesn't need an email every time a borrower
  hasn't finished uploading yet.

Uses the pre-existing `decision_results` table and its 5-value enum
(`APPROVED`, `DECLINED`, `MANUAL_REVIEW`, `MORE_DOCUMENTS_REQUIRED`,
`PENDING`) — `DECLINED`/`PENDING` still unused, available for a future
more sophisticated version.

## Update — Aug 30: MANUAL_REVIEW Now Notifies the Broker
Closed the gap logged in the original `WF010_status.md` ("only handles the
APPROVED path... a broker has no way to know an application needs their
attention"). Added a new IF node, `Needs Broker Attention?`, immediately
after `Log Agent Execution (Blocked)`:
- `final_decision === 'MANUAL_REVIEW'` → calls WF-010 (same Execute
  Sub-workflow pattern as the APPROVED path, `waitForSubWorkflow: true`) →
  `Respond Blocked`.
- Otherwise (`MORE_DOCUMENTS_REQUIRED`) → straight to `Respond Blocked`,
  no notification.

Required a corresponding change in WF-010 itself: `Compose Broker Email`
now branches its subject/body by `final_decision` — APPROVED keeps the
original "ready for review" framing, MANUAL_REVIEW gets a distinct
"Action needed" subject and a headline explaining a cross-validation
discrepancy needs broker judgment. WF-010 already had `final_decision` and
`decision_reason` available from its own `Get Application Decision
Context` query, so no new data plumbing was needed — just new composition
logic.

### Test — MANUAL_REVIEW branch, real data
- Re-broke the real name-match on application `f0ec4f3c-...` (temporarily
  reverted the bank statement's `full_name` back to `"GAVINI BHARGAV"`, the
  same test-data correction technique used on Aug 27, this time in
  reverse) to get a genuine FAILED cross-validation without fabricating a
  new application.
- Ran WF-007 (confirmed FAILED, 4 real mismatches — all 3 payslips × the
  broken bank statement) then WF-008.
- DB-verified: `decision_results.final_decision: MANUAL_REVIEW`, real
  4-mismatch reason text. `messages` row for the new broker email —
  `delivery_status: SENT`, subject `"Action needed: Application
  APP-TEST-0001 — Test Borrower"`, body correctly used the new
  MANUAL_REVIEW framing and included the real mismatch details.
- Restored the bank statement's `full_name` back to the correct value
  afterward and re-ran WF-007 + WF-008 to restore the application's
  genuine `APPROVED` state — confirmed via `decision_results` before
  moving on. No test artifacts left in an inconsistent state.

## Test 1 — MANUAL_REVIEW branch (original, Aug 27)
- Execution #590, real cross-validation FAILED (genuine `full_name`
  mismatch from WF-007 testing).
- DB-verified: `decision_results` row correct, `confidence_score: 100.00`.
- *(At this point, Aug 27, no broker notification existed yet for this
  path — see Update above for when that was added.)*

## Test 2 — APPROVED branch (original, Aug 27)
- Real PASSED cross-validation after a test-data name correction.
- DB-verified: `decision_results.final_decision: APPROVED`,
  `confidence_score: 100.00`.

## Known Gaps, Logged Not Blocking
- Same `execution_duration_ms`/`completed_at` null gap as every other
  workflow in this pipeline.
- `confidence_score` is a flat 100 on every decision, not derived from
  actual match/mismatch ratios. Fine for this simple version.
- `MORE_DOCUMENTS_REQUIRED` path (no cross-validation record at all) still
  not separately tested with real data — both real tests to date had an
  actual cross-validation record, PASSED or FAILED. Low risk, code path is
  straightforward.

## STUB Nodes Still Open
None — both `Trigger WF-010 Broker Notification (Approved)` and `Trigger
WF-010 Broker Notification (Manual Review)` are real, live, wired
connections as of Aug 30. WF-008 has no remaining stubs.

## Repo Note
`WF008_Decision_Agent.json` should be re-exported from n8n and re-uploaded
to the repo — the version currently there (if any) predates the Aug 30
`Needs Broker Attention?` addition.

## Next Up
- `MORE_DOCUMENTS_REQUIRED` real-data test, if it becomes a priority.
- Everything else from the Aug 27/30 pending list is now closed.
