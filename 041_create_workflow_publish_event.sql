BEGIN;

CREATE OR REPLACE FUNCTION workflow.publish_event
(
    p_workflow_instance_id       UUID,
    p_workflow_execution_id      UUID,
    p_workflow_step_execution_id UUID DEFAULT NULL,
    p_workflow_transition_id     UUID DEFAULT NULL,
    p_selected_transition_id     UUID DEFAULT NULL,
    p_workflow_definition_id     UUID,
    p_loan_application_id        UUID DEFAULT NULL,
    p_borrower_id                UUID DEFAULT NULL,
    p_source_agent_id            UUID DEFAULT NULL,
    p_event_name                 VARCHAR,
    p_event_category             event_category_enum,
    p_payload                    JSONB DEFAULT '{}'::jsonb,
    p_metadata                   JSONB DEFAULT '{}'::jsonb,
    p_correlation_id             UUID DEFAULT NULL,
    p_causation_id               UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS
$$
DECLARE
    v_event_id UUID;
BEGIN

    INSERT INTO workflow_events
    (
        workflow_instance_id,
        workflow_execution_id,
        workflow_step_execution_id,
        workflow_transition_id,
        selected_transition_id,
        workflow_definition_id,
        loan_application_id,
        borrower_id,
        source_agent_id,
        event_name,
        event_category,
        event_status,
        correlation_id,
        causation_id,
        payload,
        metadata,
        occurred_at
    )
    VALUES
    (
        p_workflow_instance_id,
        p_workflow_execution_id,
        p_workflow_step_execution_id,
        p_workflow_transition_id,
        p_selected_transition_id,
        p_workflow_definition_id,
        p_loan_application_id,
        p_borrower_id,
        p_source_agent_id,
        p_event_name,
        p_event_category,
        'PENDING'::event_status_enum,
        p_correlation_id,
        p_causation_id,
        COALESCE(p_payload, '{}'::jsonb),
        COALESCE(p_metadata, '{}'::jsonb),
        NOW()
    )
    RETURNING id
    INTO v_event_id;

    RETURN v_event_id;

END;
$$;

COMMENT ON FUNCTION workflow.publish_event IS
'Publishes a workflow event into the workflow_events outbox for asynchronous processing.';

COMMIT;