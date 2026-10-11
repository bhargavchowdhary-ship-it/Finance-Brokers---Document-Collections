-- =====================================================
-- 029_create_workflow_events.sql
-- =====================================================
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='event_category_enum') THEN
        CREATE TYPE event_category_enum AS ENUM
        ('BUSINESS','SYSTEM','AI_AGENT','WORKFLOW','USER','INTEGRATION');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='event_status_enum') THEN
        CREATE TYPE event_status_enum AS ENUM
        ('PENDING','PROCESSING','PROCESSED','FAILED','IGNORED');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS workflow_events
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_instance_id UUID NOT NULL,
    workflow_execution_id UUID NOT NULL,
    workflow_step_execution_id UUID,
    workflow_transition_id UUID,
    selected_transition_id UUID,
    workflow_definition_id UUID NOT NULL,

    loan_application_id UUID,
    borrower_id UUID,
    source_agent_id UUID,

    event_name VARCHAR(150) NOT NULL,
    event_category event_category_enum NOT NULL DEFAULT 'BUSINESS',
    event_status event_status_enum NOT NULL DEFAULT 'PENDING',

    correlation_id UUID,
    causation_id UUID,

    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_we_instance
        FOREIGN KEY (workflow_instance_id)
        REFERENCES workflow_instances(id),

    CONSTRAINT fk_we_execution
        FOREIGN KEY (workflow_execution_id)
        REFERENCES workflow_executions(id),

    CONSTRAINT fk_we_step_execution
        FOREIGN KEY (workflow_step_execution_id)
        REFERENCES workflow_step_executions(id),

    CONSTRAINT fk_we_transition
        FOREIGN KEY (workflow_transition_id)
        REFERENCES workflow_transitions(id),

    CONSTRAINT fk_we_selected_transition
        FOREIGN KEY (selected_transition_id)
        REFERENCES workflow_transitions(id),

    CONSTRAINT fk_we_definition
        FOREIGN KEY (workflow_definition_id)
        REFERENCES workflow_definitions(id),

    CONSTRAINT fk_we_application
        FOREIGN KEY (loan_application_id)
        REFERENCES loan_applications(id),

    CONSTRAINT fk_we_borrower
        FOREIGN KEY (borrower_id)
        REFERENCES borrowers(id),

    CONSTRAINT fk_we_agent
        FOREIGN KEY (source_agent_id)
        REFERENCES ai_agents(id)
);

CREATE INDEX IF NOT EXISTS idx_we_instance ON workflow_events(workflow_instance_id);
CREATE INDEX IF NOT EXISTS idx_we_execution ON workflow_events(workflow_execution_id);
CREATE INDEX IF NOT EXISTS idx_we_step_execution ON workflow_events(workflow_step_execution_id);
CREATE INDEX IF NOT EXISTS idx_we_transition ON workflow_events(workflow_transition_id);
CREATE INDEX IF NOT EXISTS idx_we_selected_transition ON workflow_events(selected_transition_id);
CREATE INDEX IF NOT EXISTS idx_we_event_name ON workflow_events(event_name);
CREATE INDEX IF NOT EXISTS idx_we_status ON workflow_events(event_status);
CREATE INDEX IF NOT EXISTS idx_we_category ON workflow_events(event_category);
CREATE INDEX IF NOT EXISTS idx_we_occurred ON workflow_events(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_we_correlation ON workflow_events(correlation_id);
CREATE INDEX IF NOT EXISTS idx_we_payload ON workflow_events USING GIN(payload);
CREATE INDEX IF NOT EXISTS idx_we_metadata ON workflow_events USING GIN(metadata);

COMMENT ON TABLE workflow_events IS
'Immutable business event bus for workflow orchestration and AI agents.';

COMMIT;
