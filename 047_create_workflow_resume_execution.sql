BEGIN;

CREATE OR REPLACE FUNCTION workflow.resume_execution
(
    p_workflow_execution_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS
$$
DECLARE
    v_instance_id UUID;
    v_definition_id UUID;
    v_updated INTEGER;
BEGIN

    SELECT
        workflow_instance_id,
        workflow_definition_id
    INTO
        v_instance_id,
        v_definition_id
    FROM workflow_executions
    WHERE id = p_workflow_execution_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    UPDATE workflow_executions
    SET
        status = 'RUNNING'::workflow_execution_status_enum,
        updated_at = NOW()
    WHERE id = p_workflow_execution_id
      AND status = 'PAUSED'::workflow_execution_status_enum;

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    IF v_updated = 0 THEN
        RETURN FALSE;
    END IF;

    UPDATE workflow_instances
    SET
        workflow_status = 'IN_PROGRESS'::workflow_status_enum,
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = v_instance_id;

    PERFORM workflow.publish_event
    (
        p_workflow_instance_id   => v_instance_id,
        p_workflow_execution_id  => p_workflow_execution_id,
        p_workflow_definition_id => v_definition_id,
        p_event_name             => 'WORKFLOW_EXECUTION_RESUMED',
        p_event_category         => 'WORKFLOW'::event_category_enum,
        p_payload                => '{}'::jsonb
    );

    RETURN TRUE;

END;
$$;

COMMENT ON FUNCTION workflow.resume_execution IS
'Resumes a paused workflow execution and publishes WORKFLOW_EXECUTION_RESUMED event.';

COMMIT;