-- 026_create_workflow_transitions.sql
-- Production migration scaffold
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'transition_type_enum'
    ) THEN
        CREATE TYPE transition_type_enum AS ENUM (
            'NORMAL',
            'CONDITIONAL',
            'SUCCESS',
            'FAILURE',
            'TIMEOUT',
            'ROLLBACK',
            'PARALLEL',
            'HUMAN_APPROVAL',
            'TERMINAL'
        );
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS workflow_transitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_definition_id UUID NOT NULL,
    from_stage_id UUID NOT NULL,
    to_stage_id UUID NOT NULL,

    next_step_id UUID,
    execution_policy_id UUID,

    transition_name VARCHAR(150) NOT NULL,
    event_name VARCHAR(150) NOT NULL,
    transition_type transition_type_enum NOT NULL DEFAULT 'NORMAL',

    priority INTEGER NOT NULL DEFAULT 100,

    condition_expression JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    success_transition_id UUID,
    failure_transition_id UUID,
    timeout_transition_id UUID,
    rollback_transition_id UUID,

    allow_parallel BOOLEAN NOT NULL DEFAULT FALSE,
    requires_human_approval BOOLEAN NOT NULL DEFAULT FALSE,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_wt_definition
        FOREIGN KEY (workflow_definition_id)
        REFERENCES workflow_definitions(id),

    CONSTRAINT fk_wt_from_stage
        FOREIGN KEY (from_stage_id)
        REFERENCES workflow_stages(id),

    CONSTRAINT fk_wt_to_stage
        FOREIGN KEY (to_stage_id)
        REFERENCES workflow_stages(id),

    CONSTRAINT fk_wt_step
        FOREIGN KEY (next_step_id)
        REFERENCES workflow_steps(id),

    CONSTRAINT fk_wt_execution_policy
        FOREIGN KEY (execution_policy_id)
        REFERENCES execution_policies(id)
);

ALTER TABLE workflow_transitions
    ADD CONSTRAINT fk_wt_success
    FOREIGN KEY (success_transition_id)
    REFERENCES workflow_transitions(id);

ALTER TABLE workflow_transitions
    ADD CONSTRAINT fk_wt_failure
    FOREIGN KEY (failure_transition_id)
    REFERENCES workflow_transitions(id);

ALTER TABLE workflow_transitions
    ADD CONSTRAINT fk_wt_timeout
    FOREIGN KEY (timeout_transition_id)
    REFERENCES workflow_transitions(id);

ALTER TABLE workflow_transitions
    ADD CONSTRAINT fk_wt_rollback
    FOREIGN KEY (rollback_transition_id)
    REFERENCES workflow_transitions(id);

CREATE INDEX IF NOT EXISTS idx_wt_definition ON workflow_transitions(workflow_definition_id);
CREATE INDEX IF NOT EXISTS idx_wt_from_stage ON workflow_transitions(from_stage_id);
CREATE INDEX IF NOT EXISTS idx_wt_to_stage ON workflow_transitions(to_stage_id);
CREATE INDEX IF NOT EXISTS idx_wt_event ON workflow_transitions(event_name);
CREATE INDEX IF NOT EXISTS idx_wt_policy ON workflow_transitions(execution_policy_id);
CREATE INDEX IF NOT EXISTS idx_wt_active ON workflow_transitions(is_active);
CREATE INDEX IF NOT EXISTS idx_wt_priority ON workflow_transitions(priority);
CREATE INDEX IF NOT EXISTS idx_wt_condition_gin
ON workflow_transitions USING GIN(condition_expression);

DROP TRIGGER IF EXISTS trg_workflow_transitions_updated_at
ON workflow_transitions;

CREATE TRIGGER trg_workflow_transitions_updated_at
BEFORE UPDATE ON workflow_transitions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

COMMIT;