BEGIN;

CREATE OR REPLACE FUNCTION workflow.complete_step
(
    p_workflow_step_execution_id UUID,
    p_output_payload JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE
(
    workflow_execution_id UUID,
    workflow_step_execution_id UUID,
    workflow_transition_id UUID,
    next_step_id UUID,
    is_workflow_complete BOOLEAN
)
LANGUAGE plpgsql
AS
$$
DECLARE

    v_step_execution     workflow_step_executions%ROWTYPE;
    v_execution          workflow_executions%ROWTYPE;
    v_step               workflow_steps%ROWTYPE;
    v_transition         workflow_transitions%ROWTYPE;

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
        RAISE EXCEPTION 'Workflow Step Execution not found.';
    END IF;

    --------------------------------------------------------------------
    -- Lock Workflow Execution
    --------------------------------------------------------------------

    SELECT *
    INTO v_execution
    FROM workflow_executions
    WHERE id = v_step_execution.workflow_execution_id
    FOR UPDATE;

    --------------------------------------------------------------------
    -- Lock Workflow Step
    --------------------------------------------------------------------

    SELECT *
    INTO v_step
    FROM workflow_steps
    WHERE id = v_step_execution.workflow_step_id;

    --------------------------------------------------------------------
    -- Complete Step Execution
    --------------------------------------------------------------------

    UPDATE workflow_step_executions
    SET
        status = 'COMPLETED',
        completed_at = NOW(),
        execution_duration_ms =
            EXTRACT(EPOCH FROM (NOW() - started_at)) * 1000,
        output_payload = p_output_payload,
        updated_at = NOW()
    WHERE id = p_workflow_step_execution_id;

    --------------------------------------------------------------------
    -- Resolve Next Transition
    --------------------------------------------------------------------

    SELECT wt.*
    INTO v_transition
    FROM workflow_transitions wt
    JOIN workflow_steps ws
      ON ws.id = wt.next_step_id
    WHERE
        wt.workflow_definition_id = v_execution.workflow_definition_id
    AND ws.execution_order > v_step.execution_order
    ORDER BY ws.execution_order
    LIMIT 1;

    --------------------------------------------------------------------
    -- Terminal Workflow
    --------------------------------------------------------------------

    IF NOT FOUND THEN

        UPDATE workflow_executions
        SET
            status = 'COMPLETED',
            completed_at = NOW(),
            execution_duration_ms =
                EXTRACT(EPOCH FROM (NOW() - started_at)) * 1000,
            updated_at = NOW()
        WHERE id = v_execution.id;

        RETURN QUERY
        SELECT
            v_execution.id,
            v_step_execution.id,
            NULL::UUID,
            NULL::UUID,
            TRUE;

        RETURN;

    END IF;

    --------------------------------------------------------------------
    -- Return Next Transition
    --------------------------------------------------------------------

    RETURN QUERY

    SELECT

        v_execution.id,

        v_step_execution.id,

        v_transition.id,

        v_transition.next_step_id,

        FALSE;

END;
$$;

COMMIT;