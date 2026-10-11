BEGIN;

CREATE OR REPLACE FUNCTION workflow.start_step(
    p_workflow_execution_id UUID
)
RETURNS TABLE
(
    workflow_step_execution_id UUID,
    workflow_step_id UUID,
    workflow_transition_id UUID,
    ai_agent_id UUID,
    step_code VARCHAR,
    step_name VARCHAR,
    execution_order INTEGER
)
LANGUAGE plpgsql
AS
$$
DECLARE

    v_execution              workflow_executions%ROWTYPE;
    v_step                   workflow_steps%ROWTYPE;
    v_transition             workflow_transitions%ROWTYPE;
    v_step_execution_id      UUID;

BEGIN

    ------------------------------------------------------------------
    -- Lock execution
    ------------------------------------------------------------------

    SELECT *
    INTO v_execution
    FROM workflow_executions
    WHERE id = p_workflow_execution_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Workflow execution not found.';
    END IF;

    ------------------------------------------------------------------
    -- First step
    ------------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM workflow_step_executions
        WHERE workflow_execution_id = p_workflow_execution_id
    )
    THEN

        SELECT ws.*
        INTO v_step
        FROM workflow_steps ws
        WHERE ws.workflow_definition_id = v_execution.workflow_definition_id
        ORDER BY
            ws.execution_order
        LIMIT 1;

        v_transition := NULL;

    ELSE

        ------------------------------------------------------------------
        -- Next transition
        ------------------------------------------------------------------

        SELECT wt.*
        INTO v_transition
        FROM workflow_transitions wt
        JOIN workflow_step_executions wse
             ON wse.workflow_transition_id = wt.id
        WHERE
            wse.workflow_execution_id = p_workflow_execution_id
        ORDER BY
            wse.execution_order DESC
        LIMIT 1;

        SELECT ws.*
        INTO v_step
        FROM workflow_steps ws
        WHERE ws.id = v_transition.next_step_id;

    END IF;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No executable workflow step found.';
    END IF;

    ------------------------------------------------------------------
    -- Create Step Execution
    ------------------------------------------------------------------

    INSERT INTO workflow_step_executions
    (
        workflow_execution_id,
        workflow_instance_id,
        workflow_step_id,
        workflow_transition_id,
        execution_order,
        attempt_number,
        status,
        started_at,
        input_payload,
        output_payload,
        error_payload,
        metadata
    )
    VALUES
    (
        v_execution.id,
        v_execution.workflow_instance_id,
        v_step.id,
        v_transition.id,
        COALESCE
        (
            (
                SELECT MAX(execution_order)+1
                FROM workflow_step_executions
                WHERE workflow_execution_id=v_execution.id
            ),
            1
        ),
        1,
        'RUNNING',
        now(),
        '{}'::jsonb,
        '{}'::jsonb,
        '{}'::jsonb,
        '{}'::jsonb
    )
    RETURNING id
    INTO v_step_execution_id;

    ------------------------------------------------------------------
    -- Return
    ------------------------------------------------------------------

    RETURN QUERY

    SELECT

        v_step_execution_id,

        v_step.id,

        v_transition.id,

        v_step.ai_agent_id,

        v_step.step_code,

        v_step.step_name,

        v_step.execution_order;

END;
$$;

COMMIT;