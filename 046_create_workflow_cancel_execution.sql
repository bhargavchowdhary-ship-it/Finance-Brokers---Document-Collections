BEGIN;

CREATE OR REPLACE FUNCTION workflow.cancel_execution
(
    p_workflow_execution_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS
$$
DECLARE
    v_instance_id UUID;
    v_updated INTEGER;
BEGIN

    SELECT workflow_instance_id
    INTO v_instance_id
    FROM workflow_executions
    WHERE id = p_workflow_execution_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    UPDATE workflow_executions
    SET
        status = 'CANCELLED'::workflow_execution_status_enum,
        completed_at = NOW(),
        execution_duration_ms =
            EXTRACT(EPOCH FROM (NOW() - started_at)) * 1000,
        error_message = COALESCE(p_reason, error_message),
        updated_at = NOW()
    WHERE id = p_workflow_execution_id
      AND status IN
      (
          'PENDING'::workflow_execution_status_enum,
          'RUNNING'::workflow_execution_status_enum,
          'WAITING'::workflow_execution_status_enum,
          'PAUSED'::workflow_execution_status_enum
      );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    IF v_updated = 0 THEN
        RETURN FALSE;
    END IF;

    UPDATE workflow_instances
    SET
        workflow_status = 'CANCELLED'::workflow_status_enum,
        completed_at = NOW(),
        last_activity_at = NOW(),
        failure_reason = COALESCE(p_reason, failure_reason),
        updated_at = NOW()
    WHERE id = v_instance_id;

    PERFORM workflow.publish_event
    (
        p_workflow_instance_id       => v_instance_id,
        p_workflow_execution_id      => p_workflow_execution_id,
        p_workflow_definition_id     => (
            SELECT workflow_definition_id
            FROM workflow_executions
            WHERE id = p_workflow_execution_id
        ),
        p_event_name                 => 'WORKFLOW_EXECUTION_CANCELLED',
        p_event_category             => 'WORKFLOW'::event_category_enum,
        p_payload                    => jsonb_build_object(
                                            'reason', p_reason
                                        )
    );

    RETURN TRUE;

END;
$$;

COMMENT ON FUNCTION workflow.cancel_execution IS
'Cancels an active workflow execution and publishes WORKFLOW_EXECUTION_CANCELLED event.';

COMMIT;