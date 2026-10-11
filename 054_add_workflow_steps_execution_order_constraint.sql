-- ============================================================================
-- Migration : 054_add_workflow_steps_execution_order_constraint.sql
-- Schema    : workflow
-- Purpose   : Fix seed data collision in workflow_steps.execution_order and
--             lock the column with a uniqueness constraint so this class of
--             bug cannot recur.
--
-- Context   : workflow_steps had duplicate execution_order values across
--             different steps under the same workflow_definition_id
--             (6 steps at order=1, 3 steps at order=2 for LOAN_PROCESSING).
--             This caused non-deterministic step ordering in
--             workflow.start_step() once execution reached the colliding
--             range, producing silent stalls with no error (n8n reported
--             "Succeeded" while the recursion dead-ended).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Correct sequence for LOAN_PROCESSING (workflow_definition_id below is the
-- known-good ID for this environment; re-verify before running in a fresh
-- environment).
-- ----------------------------------------------------------------------------

UPDATE workflow_steps SET execution_order = 1 WHERE step_code = 'CONVERSATION_MANAGER'    AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 2 WHERE step_code = 'DOCUMENT_INTAKE'         AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 3 WHERE step_code = 'OCR_PROCESSING'          AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 4 WHERE step_code = 'DOCUMENT_INTELLIGENCE'   AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 5 WHERE step_code = 'DOCUMENT_VERIFICATION'   AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 6 WHERE step_code = 'CROSS_VALIDATION'        AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 7 WHERE step_code = 'DECISION_ENGINE'         AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 8 WHERE step_code = 'BROKER_REVIEW'           AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';
UPDATE workflow_steps SET execution_order = 9 WHERE step_code = 'APPLICATION_SUBMISSION'  AND workflow_definition_id = '03d54614-fa99-4df2-bffc-e40abc943b55';

-- ----------------------------------------------------------------------------
-- Lock it. Prevents this class of seeding bug from ever landing silently
-- again — any future INSERT/UPDATE that collides will fail loudly instead
-- of causing a silent runtime stall.
-- ----------------------------------------------------------------------------

ALTER TABLE workflow_steps
ADD CONSTRAINT uq_workflow_steps_definition_order
UNIQUE (workflow_definition_id, execution_order);

COMMENT ON CONSTRAINT uq_workflow_steps_definition_order ON workflow_steps IS
'Prevents duplicate execution_order values within the same workflow_definition_id. Added after a seed collision caused silent step-ordering failures in WF-002.';

COMMIT;
