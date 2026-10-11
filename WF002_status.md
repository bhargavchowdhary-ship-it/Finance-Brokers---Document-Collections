# WF-002 Workflow Manager — Status

**Status: CLOSED (AI-agent chain, steps 1–7). Human-checkpoint steps (8–9) are a scoped, documented gap — not blocking WF-003 start.**

## Verified Working
Full recursive orchestrator (31 nodes), self-calls via `{{ $workflow.id }}` per step.
Steps 1–7 (`CONVERSATION_MANAGER` → `DECISION_ENGINE`) complete cleanly in strict
sequence — confirmed via direct DB query (`workflow_step_executions`), not just
n8n's "Succeeded" UI badge. Three consecutive clean end-to-end runs with no
manual node intervention.

## Bugs Found & Fixed This Session

### 1. Seed data collision — `workflow_steps.execution_order`
`execution_order` had duplicate values across different steps under the same
`workflow_definition_id` (6 steps at `order=1`, 3 at `order=2`). This caused
non-deterministic step ordering once the engine reached the colliding range.

**Fix:** Reset all 9 steps to correct sequential order (1–9), then locked it:
```sql
ALTER TABLE workflow_steps
ADD CONSTRAINT uq_workflow_steps_definition_order
UNIQUE (workflow_definition_id, execution_order);
```
See migration `054_add_workflow_steps_execution_order_constraint.sql`.

### 2. Root cause of the CROSS_VALIDATION stall (the real bug, took 2 days to isolate)
`Route To Agent` (switch node) compares `Get Step Detail`'s `agent_code` field.
That field is sourced from the **`ai_agents` table** (via
`LEFT JOIN ai_agents aa ON aa.id = ws.ai_agent_id`) — **not**
`workflow_steps.step_code`. Routing Rule 6 checked for `'CROSS_VALIDATION'`,
but the real `ai_agents.agent_code` value is `'CROSS_VALIDATION_AGENT'`
(consistent with the `_AGENT` suffix pattern used by `OCR_AGENT`,
`VERIFICATION_AGENT`, `DECISION_AGENT`, `REMINDER_AGENT`).

Mismatch → silent fallthrough (`fallbackOutput: "none"`) → no error, execution
reports "Succeeded" in n8n, but the step never completes. This is why it looked
like a race condition / manual-testing artifact for two days before the actual
cause was found.

**Fix:** Changed Rule 6's `rightValue` from `CROSS_VALIDATION` to
`CROSS_VALIDATION_AGENT` in the `Route To Agent` node. **Saved AND Published**
(critical — draft/Autosave changes are not picked up by the recursive
self-call, which always invokes the published version. Cost one full extra
test cycle this session).

All other routing rules (1–5, 7) cross-checked against live `ai_agents.agent_code`
values — no other mismatches found.

## Known, Scoped Gap — Do NOT Patch Blind
`BROKER_REVIEW` (step 8) and `APPLICATION_SUBMISSION` (step 9) have
`ai_agent_id = NULL` — human checkpoints, no AI agent. `Route To Agent` has no
routing path for null/missing `agent_code`, so execution dead-ends silently at
step 8, same symptom as the bug above but this one is a **missing feature**,
not a defect.

**Required design (build once, correctly, when WF-008/009/010 need it):**
- New routing branch in `Route To Agent`: condition `agent_code IS NULL`
  (or equivalent on `ws.ai_agent_id IS NULL` surfaced through `Get Step Detail`).
- That branch does **not** call `Complete Step` immediately. It should:
  1. Publish a `STEP_AWAITING_HUMAN` event.
  2. Set `workflow_step_executions.status` to a new value (e.g. `AWAITING_INPUT`
     — check if the enum needs extending via migration).
  3. **Stop the recursion** — no self-call to continue.
- A separate, externally-triggered call (broker approves in UI/Telegram/etc.)
  invokes `Complete Step` from outside the recursion to resume the chain.

## Process Lessons Learned
1. **Always Save AND Publish before testing.** Draft changes are invisible to
   the recursive self-call.
2. **Trust the DB query over the n8n "Succeeded" badge.** A green execution
   does not mean the logic did what you expect — proven 4 times this week.
3. **Reset test state with a function, not hand-typed SQL every time.** See
   `workflow.reset_instance_for_test()` recommended in migration notes.

## Reusable Test Instance
`workflow_instance_id = '077641e1-b3b2-4ba2-9dfa-9fd3929ad710'`
Currently `FAILED`/clean. Safe to reuse — `start_execution()` creates a new
execution automatically since no active (`PENDING`/`RUNNING`) execution exists
for this instance.

## Next Up
WF-003 Document Intake. Reference `Shared_Payload_&_Schemas.txt` for the
Workflow Manager → Document Intake contract:
```json
{
  "workflow_action": "START_DOCUMENT_INTAKE",
  "workflow_instance_id": "",
  "workflow_execution_id": "",
  "workflow_step_execution_id": "",
  "application_id": "",
  "borrower_id": "",
  "broker_id": "",
  "attachments": []
}
```
