-- ============================================================
-- TABLE: ai_agent_executions
-- ============================================================

CREATE TABLE ai_agent_executions (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    application_id UUID NOT NULL,

    conversation_session_id UUID,

    agent_name VARCHAR(100) NOT NULL,

    execution_status VARCHAR(30) NOT NULL,

    trigger_source VARCHAR(50) NOT NULL,

    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    completed_at TIMESTAMPTZ,

    execution_duration_ms INTEGER,

    input_payload JSONB,

    output_payload JSONB,

    error_message TEXT,

    prompt_tokens INTEGER,

    completion_tokens INTEGER,

    total_tokens INTEGER,

    estimated_cost_usd NUMERIC(10,6),

    model_name VARCHAR(100),

    retry_count INTEGER NOT NULL DEFAULT 0,

    workflow_execution_id VARCHAR(255),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_ai_agent_executions_application
        FOREIGN KEY (application_id)
        REFERENCES loan_applications(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_ai_agent_executions_conversation
        FOREIGN KEY (conversation_session_id)
        REFERENCES conversation_sessions(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_execution_status
        CHECK (
            execution_status IN (
                'RUNNING',
                'SUCCESS',
                'FAILED',
                'CANCELLED',
                'TIMEOUT'
            )
        )

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_ai_exec_application
ON ai_agent_executions(application_id);

CREATE INDEX idx_ai_exec_conversation
ON ai_agent_executions(conversation_session_id);

CREATE INDEX idx_ai_exec_agent
ON ai_agent_executions(agent_name);

CREATE INDEX idx_ai_exec_status
ON ai_agent_executions(execution_status);

CREATE INDEX idx_ai_exec_started_at
ON ai_agent_executions(started_at DESC);

CREATE INDEX idx_ai_exec_workflow
ON ai_agent_executions(workflow_execution_id);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE TRIGGER trg_ai_agent_executions_updated_at
BEFORE UPDATE
ON ai_agent_executions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- COMMENT
-- ============================================================

COMMENT ON TABLE ai_agent_executions IS
'Stores every execution performed by an AI agent including execution metadata, token usage, cost, timing and failures.';
