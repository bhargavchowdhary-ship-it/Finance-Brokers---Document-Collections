-- =====================================================
-- 027_create_workflow_executions.sql
-- =====================================================
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type
        WHERE typname = 'workflow_execution_status_enum'
    ) THEN
        CREATE TYPE workflow_execution_status_enum AS ENUM
        (
            'PENDING',
            'RUNNING',
            'COMPLETED',
            'FAILED',
            'CANCELLED',
            'TIMED_OUT'
        );
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS workflow_executions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_instance_id UUID NOT NULL,
    workflow_definition_id UUID NOT NULL,

    execution_number INTEGER NOT NULL DEFAULT 1,

    status workflow_execution_status_enum
        NOT NULL DEFAULT 'PENDING',

    trigger_source VARCHAR(100),
    triggered_by_agent_id UUID,

    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    execution_duration_ms BIGINT,

    error_message TEXT,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_we_instance
        FOREIGN KEY (workflow_instance_id)
        REFERENCES workflow_instances(id),

    CONSTRAINT fk_we_definition
        FOREIGN KEY (workflow_definition_id)
        REFERENCES workflow_definitions(id),

    CONSTRAINT fk_we_agent
        FOREIGN KEY (triggered_by_agent_id)
        REFERENCES ai_agents(id),

    CONSTRAINT chk_execution_number
        CHECK (execution_number > 0),

    CONSTRAINT uq_workflow_execution
        UNIQUE (workflow_instance_id, execution_number)
);

CREATE INDEX IF NOT EXISTS idx_wf_exec_instance
ON workflow_executions(workflow_instance_id);

CREATE INDEX IF NOT EXISTS idx_wf_exec_definition
ON workflow_executions(workflow_definition_id);

CREATE INDEX IF NOT EXISTS idx_wf_exec_status
ON workflow_executions(status);

CREATE INDEX IF NOT EXISTS idx_wf_exec_agent
ON workflow_executions(triggered_by_agent_id);

CREATE INDEX IF NOT EXISTS idx_wf_exec_started
ON workflow_executions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_wf_exec_metadata
ON workflow_executions USING GIN(metadata);

DROP TRIGGER IF EXISTS trg_workflow_executions_updated_at
ON workflow_executions;

CREATE TRIGGER trg_workflow_executions_updated_at
BEFORE UPDATE
ON workflow_executions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE workflow_executions IS
'Represents a single execution attempt of a workflow instance.';

COMMIT;
