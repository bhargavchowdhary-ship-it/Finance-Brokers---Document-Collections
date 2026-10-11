-- ============================================================================
-- Migration : 032_create_workflow_start_execution.sql
-- Schema    : workflow
-- Function  : workflow.start_execution()
-- Purpose   : Starts or resumes a workflow execution.
-- ============================================================================

BEGIN;

-- ============================================================================
-- Ensure only ONE active execution exists per workflow instance
-- ============================================================================
DROP INDEX IF EXISTS uq_active_workflow_execution;

CREATE UNIQUE INDEX uq_active_workflow_execution
ON workflow_executions(workflow_instance_id)
WHERE status IN ('PENDING','RUNNING');

-- ============================================================================
-- Function
-- ============================================================================

CREATE OR REPLACE FUNCTION workflow.start_execution
(
    p_workflow_instance_id UUID,
    p_trigger_source VARCHAR(100) DEFAULT 'SYSTEM',
    p_triggered_by_agent_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
)

RETURNS TABLE
(
    workflow_execution_id UUID,
    execution_number INTEGER,
    execution_status workflow_execution_status_enum,
    started_at TIMESTAMPTZ,
    is_existing BOOLEAN
)

LANGUAGE plpgsql

AS
$$

DECLARE

    v_instance workflow_instances%ROWTYPE;

    v_execution workflow_executions%ROWTYPE;

    v_next_execution_number INTEGER;

BEGIN

    ----------------------------------------------------------------------------
    -- Validate & Lock Workflow Instance
    ----------------------------------------------------------------------------

    SELECT *
    INTO v_instance
    FROM workflow_instances
    WHERE id = p_workflow_instance_id
    FOR UPDATE;

    IF NOT FOUND THEN

        RAISE EXCEPTION
        USING
            ERRCODE = 'P0001',
            MESSAGE = 'Workflow instance not found.';

    END IF;

    ----------------------------------------------------------------------------
    -- Existing Active Execution
    ----------------------------------------------------------------------------

    SELECT *
    INTO v_execution
    FROM workflow_executions
    WHERE workflow_instance_id = p_workflow_instance_id
      AND status IN ('PENDING','RUNNING')
    LIMIT 1;

    IF FOUND THEN

        RETURN QUERY

        SELECT

            v_execution.id,

            v_execution.execution_number,

            v_execution.status,

            v_execution.started_at,

            TRUE;

        RETURN;

    END IF;

    ----------------------------------------------------------------------------
    -- Next Execution Number
    ----------------------------------------------------------------------------

    SELECT

        COALESCE(MAX(execution_number),0) + 1

    INTO

        v_next_execution_number

    FROM workflow_executions

    WHERE workflow_instance_id = p_workflow_instance_id;

    ----------------------------------------------------------------------------
    -- Create Execution
    ----------------------------------------------------------------------------

    INSERT INTO workflow_executions
    (

        workflow_instance_id,

        workflow_definition_id,

        execution_number,

        status,

        trigger_source,

        triggered_by_agent_id,

        started_at,

        metadata

    )

    VALUES
    (

        v_instance.id,

        (
            SELECT id
            FROM workflow_definitions
            WHERE workflow_name = v_instance.workflow_name
            AND version = v_instance.workflow_version
            LIMIT 1
        ),

        v_next_execution_number,

        'RUNNING',

        p_trigger_source,

        p_triggered_by_agent_id,

        NOW(),

        p_metadata

    )

    RETURNING *

    INTO v_execution;

    ----------------------------------------------------------------------------
    -- Update Workflow Instance
    ----------------------------------------------------------------------------

    UPDATE workflow_instances

    SET

        workflow_status = 'RUNNING',

        last_activity_at = NOW()

    WHERE id = v_instance.id;

    ----------------------------------------------------------------------------
    -- Audit Event
    ----------------------------------------------------------------------------

    INSERT INTO workflow_events
    (

        workflow_instance_id,

        workflow_execution_id,

        workflow_definition_id,

        source_agent_id,

        event_name,

        event_category,

        event_status,

        payload,

        occurred_at

    )

    VALUES
    (

        v_instance.id,

        v_execution.id,

        v_execution.workflow_definition_id,

        p_triggered_by_agent_id,

        'WORKFLOW_EXECUTION_STARTED',

        'WORKFLOW',

        'PROCESSED',

        p_metadata,

        NOW()

    );

    ----------------------------------------------------------------------------
    -- Return
    ----------------------------------------------------------------------------

    RETURN QUERY

    SELECT

        v_execution.id,

        v_execution.execution_number,

        v_execution.status,

        v_execution.started_at,

        FALSE;

END;

$$;

COMMENT ON FUNCTION workflow.start_execution IS
'Starts or resumes a workflow execution. Guarantees a single active execution per workflow instance.';

COMMIT;