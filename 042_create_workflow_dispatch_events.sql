BEGIN;

CREATE OR REPLACE FUNCTION workflow.dispatch_events
(
    p_batch_size INTEGER DEFAULT 100
)
RETURNS TABLE
(
    event_id UUID,
    workflow_instance_id UUID,
    workflow_execution_id UUID,
    workflow_step_execution_id UUID,
    workflow_transition_id UUID,
    selected_transition_id UUID,
    workflow_definition_id UUID,
    loan_application_id UUID,
    borrower_id UUID,
    source_agent_id UUID,
    event_name VARCHAR,
    event_category event_category_enum,
    correlation_id UUID,
    causation_id UUID,
    payload JSONB,
    metadata JSONB,
    occurred_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS
$$
BEGIN

    RETURN QUERY

    WITH next_batch AS
    (
        SELECT id
        FROM workflow_events
        WHERE event_status = 'PENDING'::event_status_enum
        ORDER BY occurred_at
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    ),

    updated AS
    (
        UPDATE workflow_events e
        SET
            event_status = 'PROCESSING'::event_status_enum,
            processed_at = NOW()
        FROM next_batch nb
        WHERE e.id = nb.id
        RETURNING e.*
    )

    SELECT
        u.id,
        u.workflow_instance_id,
        u.workflow_execution_id,
        u.workflow_step_execution_id,
        u.workflow_transition_id,
        u.selected_transition_id,
        u.workflow_definition_id,
        u.loan_application_id,
        u.borrower_id,
        u.source_agent_id,
        u.event_name,
        u.event_category,
        u.correlation_id,
        u.causation_id,
        u.payload,
        u.metadata,
        u.occurred_at
    FROM updated u
    ORDER BY u.occurred_at;

END;
$$;

COMMENT ON FUNCTION workflow.dispatch_events IS
'Dispatches pending workflow events by locking a batch, marking them as PROCESSING, and returning them to the caller.';

COMMIT;