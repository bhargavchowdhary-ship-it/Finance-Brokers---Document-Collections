workflow_definitions
    └── LOAN_PROCESSING

workflow_stages
    ├── INITIALIZATION
    ├── DOCUMENT_COLLECTION
    ├── DOCUMENT_PROCESSING
    ├── DOCUMENT_VERIFICATION
    ├── APPLICATION_REVIEW
    ├── APPLICATION_SUBMISSION
    ├── POST_SUBMISSION
    └── COMPLETED

workflow_steps (execution_order, verified unique per workflow_definition_id
                as of migration 054)
    1. CONVERSATION_MANAGER    (agent_code: CONVERSATION_MANAGER)
    2. DOCUMENT_INTAKE         (agent_code: DOCUMENT_INTAKE)
    3. OCR_PROCESSING          (agent_code: OCR_AGENT)
    4. DOCUMENT_INTELLIGENCE   (agent_code: DOCUMENT_INTELLIGENCE)
    5. DOCUMENT_VERIFICATION   (agent_code: VERIFICATION_AGENT)
    6. CROSS_VALIDATION        (agent_code: CROSS_VALIDATION_AGENT)
    7. DECISION_ENGINE         (agent_code: DECISION_AGENT)
    8. BROKER_REVIEW           (agent_code: NULL — human checkpoint)
    9. APPLICATION_SUBMISSION  (agent_code: NULL — human checkpoint)

## Naming Convention Note (important, caused a 2-day bug)
`workflow_steps.step_code` and `ai_agents.agent_code` are DIFFERENT strings
by design, not typos. `Route To Agent` in WF-002 routes on `agent_code`
(joined in via `Get Step Detail`), not `step_code`. When adding a new step
with an AI agent, always confirm the exact `ai_agents.agent_code` value and
use that — not an assumed/guessed name — in the routing rule.

## Known Gap — Human Checkpoint Steps
Steps with `ai_agent_id = NULL` (`BROKER_REVIEW`, `APPLICATION_SUBMISSION`)
have no routing path in `Route To Agent` yet. The engine currently dead-ends
silently when it reaches them (n8n reports "Succeeded", but the step never
completes and the recursion stops).

**Planned design** (not yet built — build once, correctly, when WF-008/009/010
are wired):
- `Route To Agent` gets a branch for `agent_code IS NULL`.
- That branch publishes a `STEP_AWAITING_HUMAN` event, sets step status to
  `AWAITING_INPUT` (enum extension may be required), and does **not**
  self-call to continue — recursion pauses here by design.
- An external trigger (broker action via UI/Telegram/etc.) later calls
  `Complete Step` directly to resume the chain.

This is intentionally deferred — it is not a bug in WF-002, it's a feature
not yet built. See `WF002_status.md` for full detail.

## Testing Discipline (added after WF-002 debugging session)
1. Always **Save AND Publish** n8n changes before testing — the recursive
   self-call (`{{ $workflow.id }}`) only invokes the published version, never
   a draft/Autosave state.
2. Always confirm results via direct DB query
   (`workflow_step_executions` / `workflow_instances`) — n8n's "Succeeded"
   execution badge only means no node threw an error, not that the business
   logic completed correctly.
3. Use `workflow.reset_instance_for_test(instance_id)` (migration 055) to
   reset a stuck test instance instead of hand-typing cleanup SQL.
