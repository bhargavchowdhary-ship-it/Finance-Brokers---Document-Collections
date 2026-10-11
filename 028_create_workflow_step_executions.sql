-- =====================================================
-- 028_create_workflow_step_executions.sql
-- =====================================================
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type
        WHERE typname = 'workflow_step_execution_status_enum'
    ) THEN
        CREATE TYPE workflow_step_execution_status_enum AS ENUM
        (
            'PENDING',
            'RUNNING',
            'COMPLETED',
            'FAILED',
            'SKIPPED',
            'CANCELLED',
            'TIMED_OUT'
        );
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS workflow_step_executions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_execution_id UUID NOT NULL,
    workflow_instance_id UUID NOT NULL,
    workflow_step_id UUID NOT NULL,
    workflow_transition_id UUID,

    execution_order INTEGER NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,

    status workflow_step_execution_status_enum
        NOT NULL DEFAULT 'PENDING',

    ai_agent_execution_id UUID,

    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    execution_duration_ms BIGINT,

    input_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_wse_execution
        FOREIGN KEY (workflow_execution_id)
        REFERENCES workflow_executions(id),

    CONSTRAINT fk_wse_instance
        FOREIGN KEY (workflow_instance_id)
        REFERENCES workflow_instances(id),

    CONSTRAINT fk_wse_step
        FOREIGN KEY (workflow_step_id)
        REFERENCES workflow_steps(id),

    CONSTRAINT fk_wse_transition
        FOREIGN KEY (workflow_transition_id)
        REFERENCES workflow_transitions(id),

    CONSTRAINT fk_wse_agent_execution
        FOREIGN KEY (ai_agent_execution_id)
        REFERENCES ai_agent_executions(id),

    CONSTRAINT chk_wse_attempt CHECK (attempt_number > 0),
    CONSTRAINT chk_wse_order CHECK (execution_order > 0),

    CONSTRAINT uq_wse_execution_step_attempt
        UNIQUE (workflow_execution_id, workflow_step_id, attempt_number)
);

CREATE INDEX IF NOT EXISTS idx_wse_execution
ON workflow_step_executions(workflow_execution_id);

CREATE INDEX IF NOT EXISTS idx_wse_instance
ON workflow_step_executions(workflow_instance_id);

CREATE INDEX IF NOT EXISTS idx_wse_step
ON workflow_step_executions(workflow_step_id);

CREATE INDEX IF NOT EXISTS idx_wse_transition
ON workflow_step_executions(workflow_transition_id);

CREATE INDEX IF NOT EXISTS idx_wse_status
ON workflow_step_executions(status);

CREATE INDEX IF NOT EXISTS idx_wse_agent_execution
ON workflow_step_executions(ai_agent_execution_id);

CREATE INDEX IF NOT EXISTS idx_wse_started
ON workflow_step_executions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_wse_input_gin
ON workflow_step_executions USING GIN(input_payload);

CREATE INDEX IF NOT EXISTS idx_wse_output_gin
ON workflow_step_executions USING GIN(output_payload);

CREATE INDEX IF NOT EXISTS idx_wse_error_gin
ON workflow_step_executions USING GIN(error_payload);

DROP TRIGGER IF EXISTS trg_workflow_step_executions_updated_at
ON workflow_step_executions;

CREATE TRIGGER trg_workflow_step_executions_updated_at
BEFORE UPDATE ON workflow_step_executions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE workflow_step_executions IS
'Runtime execution record for each workflow step executed within a workflow execution.';

COMMIT;
