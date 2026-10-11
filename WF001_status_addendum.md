# WF-001 Conversation Manager — Status Addendum (Aug 30)

No prior `WF001_status.md` existed in the repo (only `WF001_status__1_.md`,
an older/differently-named file — check that one too if reconciling
history). This addendum covers a critical bug found and fixed today during
the project's first real, fully-untouched end-to-end pipeline test.

## Critical Bug Found and Fixed — Multi-Application Document Misfiling

**Severity: critical.** Real borrower document uploads could silently be
written against the wrong loan application whenever more than one
application existed with `application_status = 'DRAFT'` in the system.

### Root cause
The `Loan Application` node used the Supabase node's `getAll` operation
with **two AND'd filter conditions**:
```
{ keyName: 'id', condition: 'eq', keyValue: '={{$(\'Application Borrower\').item.json.application_id}}' },
{ keyName: 'application_status', condition: 'eq', keyValue: 'DRAFT' }
```
Live execution #598 (Aug 30) proved the `id` condition was being silently
ignored — the node returned **all 5 DRAFT applications system-wide**
instead of the one specific application the borrower belongs to.
Downstream code (`Build Conversation Context`) implicitly used
`.first()`/the first returned row. Supabase's `getAll` with no explicit
`orderBy` returns rows in an unspecified order (in practice, oldest-first
by creation), so the **oldest** DRAFT application in the entire system
won — not the borrower's actual application.

### Real-world impact
A real borrower (linked via Telegram `chat_id`, correctly resolved to
`f0ec4f3c-...` / APP-TEST-0001 at every step up to and including
`Application Borrower`) had two passport photos misfiled onto a
**completely different** loan application (`84397920-...` /
APP-2026-000001, a different real borrower "John Smith"). OCR, Document
Intelligence, and Verification all ran successfully — against the wrong
file.

### Why it didn't cause worse damage
WF-007 Cross Validation's own readiness self-gate (built and closed on
Aug 27) happened to catch this: application `84397920` still had other
required checklist items unverified, so WF-007 correctly routed to
`Respond Waiting` and never reached cross-validation, decision, or broker
notification. **This was accidental containment, not a bug fix** — the
self-gate wasn't designed to guard against misfiling, it just happened to.
The misfiled `documents`, `document_intelligence_results`,
`verification_results`, and `ai_agent_executions` rows were manually
identified and deleted; `document_checklists` for the correct application
(`560ba409-...`, the passport slot on `f0ec4f3c`) was restored to its
prior `REQUESTED` state.

### Fix
Changed `Loan Application` from `getAll` with 2 conditions to `get` with a
single `id` condition — the same proven-reliable pattern used successfully
throughout WF-006 through WF-010 (hundreds of real executions, zero
instances of this bug in any single-condition node). The
`application_status = 'DRAFT'` safety check was dropped in this fix,
**logged as a known gap, not blocking** — every real test application in
the system is still `DRAFT` today, so there's no current behavioral
regression, but a real production system will eventually have
non-DRAFT applications and this check should be reinstated properly (see
Next Up).

### Project-wide audit performed
Scanned every Supabase `getAll`/`get` node across all 10 workflow JSONs in
the repo for multi-condition filters (the specific pattern that broke).
**`Loan Application` was the only instance found, project-wide.** Every
other such node — in WF-001 and every other workflow — uses exactly one
filter condition. No further remediation needed on this specific bug
class. (This does not rule out other, different bug classes existing
elsewhere — it's a targeted check, not a full audit.)

## End-to-End Pipeline Test — First Full Pass, Aug 30

Following the fix, a second identical real Telegram upload (same 2
passport photos, resent by the borrower) was used as the retest. Result:
**full, completely untouched, end-to-end success** — Telegram upload → OCR
→ Document Intelligence → Verification → Cross-Validation → Decision →
Broker Notification, ~13 seconds total pipeline time after upload, zero
manual n8n intervention.

- Both photos correctly matched to the passport checklist item.
- `p1` (data page, valid expiry 2033-09-03): VERIFIED.
- `p2` (address page, no name field extracted, `full_name: null`):
  correctly FAILED verification (completeness check), correctly triggered
  a real WF-009 reminder to the borrower via Telegram — confirmed by the
  borrower's own screenshot of the received message, matching the DB
  record exactly.
- Once all 5 required checklist items had at least one VERIFIED document,
  WF-007 auto-triggered, PASSED (all names/fields consistent), WF-008
  auto-triggered, `final_decision: APPROVED`, WF-010 auto-triggered, real
  broker email sent (`delivery_status: SENT`, real Gmail message ID).
- This is the first time the full pipeline has been proven to work
  unattended, and it also demonstrates the borrower-reply/reminder loop
  working correctly (a genuinely failed document correctly triggering a
  real reminder, separate from the successful document already satisfying
  the checklist gate).

## Known Gaps, Logged Not Blocking
- `application_status = 'DRAFT'` check dropped from `Loan Application` (see
  above). Needs a proper reinstatement once non-DRAFT applications become
  a real scenario — likely as a downstream IF-node check rather than baked
  into the Supabase filter, to avoid the same multi-condition risk.
- The `getAll`/`get`-with-multiple-conditions failure mode itself is worth
  writing up as a standing project rule (similar to the existing "always
  trace to $('Source Node')" rule from WF-005's bug #8): **never combine
  more than one filter condition on a single Supabase `getAll`/`get`
  operation — split into `get` with one condition plus a downstream IF, or
  switch to a Postgres `executeQuery` with parameterized SQL** (the pattern
  used throughout WF-006–010, zero incidents).

## Next Up
1. Reinstate an `application_status` safety check via a downstream IF node
   after `Loan Application`, rather than a second Supabase filter
   condition.
2. Non-approved broker notification path (WF-010 gap, logged in
   `WF010_status.md`) — still open.
3. Consider adding the "single filter condition only" rule explicitly to
   whatever project-wide build/audit checklist exists, given it just
   caused a real, if contained, production-grade bug.
