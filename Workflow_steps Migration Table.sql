CREATE TABLE workflow_steps
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_definition_id UUID NOT NULL,
    workflow_stage_id UUID NOT NULL,
    ai_agent_id UUID NOT NULL,

    step_code VARCHAR(100) NOT NULL,
    step_name VARCHAR(150) NOT NULL,
    description TEXT,

    execution_order INTEGER NOT NULL,

    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    allow_parallel BOOLEAN NOT NULL DEFAULT FALSE,
    stop_on_failure BOOLEAN NOT NULL DEFAULT TRUE,

    timeout_seconds INTEGER NOT NULL DEFAULT 300,
    max_retries INTEGER NOT NULL DEFAULT 3,
    retry_delay_seconds INTEGER NOT NULL DEFAULT 60,

    step_status workflow_step_status_enum
        NOT NULL DEFAULT 'ACTIVE',

    configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
    input_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_schema JSONB NOT NULL DEFAULT '{}'::jsonb,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_workflow_step_definition
        FOREIGN KEY (workflow_definition_id)
        REFERENCES workflow_definitions(id),

    CONSTRAINT fk_workflow_step_stage
        FOREIGN KEY (workflow_stage_id)
        REFERENCES workflow_stages(id),

    CONSTRAINT fk_workflow_step_agent
        FOREIGN KEY (ai_agent_id)
        REFERENCES ai_agents(id),

    CONSTRAINT uq_workflow_step_code
        UNIQUE (workflow_stage_id, step_code),

    CONSTRAINT uq_workflow_step_order
        UNIQUE (workflow_stage_id, execution_order),

    CONSTRAINT chk_timeout
        CHECK(timeout_seconds > 0),

    CONSTRAINT chk_retry
        CHECK(max_retries >= 0),

    CONSTRAINT chk_retry_delay
        CHECK(retry_delay_seconds >= 0)
);