-- ============================================================================
-- Migration : 055_create_workflow_reset_instance_for_test.sql
-- Schema    : workflow
-- Function  : workflow.reset_instance_for_test()
-- Purpose   : Testing/debugging utility. Kills any active execution on a
--             workflow instance so it can be re-triggered cleanly, without
--             hand-typing the same 3-statement cleanup block every test
--             cycle. NOT for production use — this force-fails RUNNING work.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION workflow.reset_instance_for_test
(
    p_instance_id UUID
)

RETURNS VOID

LANGUAGE plpgsql

AS
$$

BEGIN

    UPDATE workflow_executions
    SET status = 'FAILED', completed_at = now()
    WHERE workflow_instance_id = p_instance_id
      AND status IN ('PENDING','RUNNING');

    UPDATE workflow_step_executions
    SET status = 'CANCELLED', completed_at = now()
    WHERE workflow_execution_id IN (
        SELECT id FROM workflow_executions
        WHERE workflow_instance_id = p_instance_id
    )
    AND status = 'RUNNING';

    UPDATE workflow_instances
    SET workflow_status = 'FAILED', current_stage = 'FAILED'
    WHERE id = p_instance_id;

END;

$$;

COMMENT ON FUNCTION workflow.reset_instance_for_test IS
'TEST/DEBUG ONLY. Force-fails any active execution + step executions on a workflow instance so it can be re-triggered cleanly. Do not call in production paths.';

COMMIT;

-- Usage:
-- SELECT workflow.reset_instance_for_test('077641e1-b3b2-4ba2-9dfa-9fd3929ad710');
