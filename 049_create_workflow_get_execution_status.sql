BEGIN;

CREATE OR REPLACE FUNCTION workflow.get_execution_status
(
    p_workflow_execution_id UUID
)
RETURNS TABLE
(
    workflow_execution_id UUID,
    workflow_instance_id UUID,
    execution_number INTEGER,
    execution_status workflow_execution_status_enum,
    workflow_name VARCHAR,
    workflow_version INTEGER,
    current_stage VARCHAR,
    current_step VARCHAR,
    step_execution_status workflow_step_execution_status_enum,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    execution_duration_ms BIGINT,
    error_message TEXT
)
LANGUAGE plpgsql
AS
$$
BEGIN

    RETURN QUERY

    SELECT
        we.id,
        we.workflow_instance_id,
        we.execution_number,
        we.status,

        wi.workflow_name,
        wi.workflow_version,
        wi.current_stage,
        wi.current_step,

        wse.status,

        we.started_at,
        we.completed_at,
        we.execution_duration_ms,
        we.error_message

    FROM workflow_executions we

    JOIN workflow_instances wi
        ON wi.id = we.workflow_instance_id

    LEFT JOIN LATERAL
    (
        SELECT
            s.status
        FROM workflow_step_executions s
        WHERE s.workflow_execution_id = we.id
        ORDER BY s.execution_order DESC,
                 s.attempt_number DESC
        LIMIT 1
    ) wse ON TRUE

    WHERE we.id = p_workflow_execution_id;

END;
$$;

COMMENT ON FUNCTION workflow.get_execution_status IS
'Returns the current execution status, workflow status and latest workflow step execution for a workflow execution.';

COMMIT;