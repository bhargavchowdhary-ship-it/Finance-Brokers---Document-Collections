-- ============================================================================
-- Migration : 031_create_workflow_create_instance.sql
-- Schema    : workflow
-- Function  : workflow.create_instance()
-- Purpose   : Creates or returns an existing workflow instance for a loan
--             application.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION workflow.create_instance
(
    p_application_id UUID,
    p_workflow_definition_id UUID,
    p_metadata JSONB DEFAULT '{}'::jsonb
)

RETURNS TABLE
(
    workflow_instance_id UUID,
    workflow_name VARCHAR,
    workflow_version INTEGER,
    workflow_status workflow_status_enum,
    current_stage VARCHAR,
    current_step VARCHAR,
    is_existing BOOLEAN
)

LANGUAGE plpgsql

AS
$$

DECLARE

    v_instance workflow_instances%ROWTYPE;

    v_definition workflow_definitions%ROWTYPE;

BEGIN

    --------------------------------------------------------------------------
    -- Validate Loan Application
    --------------------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM loan_applications
        WHERE id = p_application_id
    )
    THEN

        RAISE EXCEPTION
        'Loan Application not found.';

    END IF;

    --------------------------------------------------------------------------
    -- Validate Workflow Definition
    --------------------------------------------------------------------------

    SELECT *
    INTO v_definition
    FROM workflow_definitions
    WHERE id = p_workflow_definition_id;

    IF NOT FOUND THEN

        RAISE EXCEPTION
        'Workflow Definition not found.';

    END IF;

    --------------------------------------------------------------------------
    -- Validate Active Workflow
    --------------------------------------------------------------------------

    IF v_definition.is_active = FALSE THEN

        RAISE EXCEPTION
        'Workflow Definition is inactive.';

    END IF;

    --------------------------------------------------------------------------
    -- Check Existing Workflow Instance
    --------------------------------------------------------------------------

    SELECT *
    INTO v_instance
    FROM workflow_instances
    WHERE application_id = p_application_id
      AND workflow_name = v_definition.workflow_name
    LIMIT 1;

    --------------------------------------------------------------------------
    -- Existing
    --------------------------------------------------------------------------

    IF FOUND THEN

        RETURN QUERY

        SELECT

            v_instance.id,

            v_instance.workflow_name,

            v_instance.workflow_version,

            v_instance.workflow_status,

            v_instance.current_stage,

            v_instance.current_step,

            TRUE;

        RETURN;

    END IF;

    --------------------------------------------------------------------------
    -- Create Workflow Instance
    --------------------------------------------------------------------------

    INSERT INTO workflow_instances
    (

        application_id,

        workflow_name,

        workflow_version,

        current_stage,

        current_step,

        workflow_status,

        progress_percentage,

        started_at,

        last_activity_at,

        metadata

    )

    VALUES
    (

        p_application_id,

        v_definition.workflow_name,

        v_definition.version,

        v_definition.initial_stage,

        v_definition.initial_step,

        'CREATED',

        0,

        NOW(),

        NOW(),

        p_metadata

    )

    RETURNING *

    INTO v_instance;

    --------------------------------------------------------------------------
    -- Return
    --------------------------------------------------------------------------

    RETURN QUERY

    SELECT

        v_instance.id,

        v_instance.workflow_name,

        v_instance.workflow_version,

        v_instance.workflow_status,

        v_instance.current_stage,

        v_instance.current_step,

        FALSE;

END;

$$;

COMMENT ON FUNCTION workflow.create_instance IS
'Creates or returns an existing workflow instance for a loan application.';

COMMIT;