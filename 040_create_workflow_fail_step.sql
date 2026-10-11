BEGIN;

CREATE OR REPLACE FUNCTION workflow.fail_step
(
    p_workflow_step_execution_id UUID,
    p_error_message TEXT,
    p_error_payload JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE
(
    workflow_execution_id UUID,
    workflow_step_execution_id UUID,
    workflow_status workflow_execution_status_enum,
    step_status workflow_step_execution_status_enum
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_step_execution workflow_step_executions%ROWTYPE;
    v_execution      workflow_executions%ROWTYPE;
BEGIN

    --------------------------------------------------------------------
    -- Lock Step Execution
    --------------------------------------------------------------------

    SELECT *
    INTO v_step_execution
    FROM workflow_step_executions
    WHERE id = p_workflow_step_execution_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Workflow Step Execution % not found.',
            p_workflow_step_execution_id;
    END IF;

    --------------------------------------------------------------------
    -- Lock Workflow Execution
    --------------------------------------------------------------------

    SELECT *
    INTO v_execution
    FROM workflow_executions
    WHERE id = v_step_execution.workflow_execution_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Workflow Execution % not found.',
            v_step_execution.workflow_execution_id;
    END IF;

    --------------------------------------------------------------------
    -- Fail Step Execution
    --------------------------------------------------------------------

    UPDATE workflow_step_executions
    SET
        status = 'FAILED',
        completed_at = NOW(),
        execution_duration_ms =
            EXTRACT(EPOCH FROM (NOW() - started_at)) * 1000,
        error_payload = p_error_payload,
        updated_at = NOW()
    WHERE id = v_step_execution.id;

    --------------------------------------------------------------------
    -- Fail Workflow Execution
    --------------------------------------------------------------------

    UPDATE workflow_executions
    SET
        status = 'FAILED',
        completed_at = NOW(),
        execution_duration_ms =
            EXTRACT(EPOCH FROM (NOW() - started_at)) * 1000,
        error_message = p_error_message,
        updated_at = NOW()
    WHERE id = v_execution.id;

    --------------------------------------------------------------------
    -- Return
    --------------------------------------------------------------------

    RETURN QUERY
    SELECT
        v_execution.id,
        v_step_execution.id,
        'FAILED'::workflow_execution_status_enum,
        'FAILED'::workflow_step_execution_status_enum;

END;
$$;

COMMIT;