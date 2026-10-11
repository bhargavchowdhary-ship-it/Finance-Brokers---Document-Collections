BEGIN;

CREATE OR REPLACE FUNCTION workflow.get_next_step
(
    p_workflow_step_execution_id UUID
)
RETURNS TABLE
(
    workflow_transition_id UUID,
    next_step_id UUID,
    transition_type transition_type_enum,
    event_name VARCHAR,
    requires_human_approval BOOLEAN,
    allow_parallel BOOLEAN
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_workflow_definition_id UUID;
    v_current_stage_id UUID;
BEGIN

    /*
        Locate current workflow stage
    */

    SELECT
        ws.workflow_definition_id,
        ws.workflow_stage_id
    INTO
        v_workflow_definition_id,
        v_current_stage_id
    FROM workflow_step_executions wse
    JOIN workflow_steps ws
        ON ws.id = wse.workflow_step_id
    WHERE wse.id = p_workflow_step_execution_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Workflow Step Execution % not found.',
            p_workflow_step_execution_id;
    END IF;

    /*
        Return highest priority active transition
    */

    RETURN QUERY

    SELECT
        wt.id,
        wt.next_step_id,
        wt.transition_type,
        wt.event_name,
        wt.requires_human_approval,
        wt.allow_parallel
    FROM workflow_transitions wt
    WHERE wt.workflow_definition_id = v_workflow_definition_id
      AND wt.from_stage_id = v_current_stage_id
      AND wt.is_active = TRUE
    ORDER BY wt.priority
    LIMIT 1;

END;
$$;

COMMENT ON FUNCTION workflow.get_next_step IS
'Returns the next workflow step based on the current workflow step execution.';

COMMIT;