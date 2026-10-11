-- ============================================================
-- TABLE: agent_execution_events
-- ============================================================

CREATE TABLE agent_execution_events (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    execution_id UUID NOT NULL,

    event_sequence INTEGER NOT NULL,

    event_type TEXT NOT NULL,

    event_status TEXT NOT NULL,

    event_source TEXT NOT NULL,

    message TEXT,

    payload JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_agent_execution_events_execution
        FOREIGN KEY (execution_id)
        REFERENCES ai_agent_executions(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_execution_events_execution
ON agent_execution_events(execution_id);

CREATE INDEX idx_execution_events_sequence
ON agent_execution_events(execution_id, event_sequence);

CREATE INDEX idx_execution_events_type
ON agent_execution_events(event_type);

CREATE INDEX idx_execution_events_created_at
ON agent_execution_events(created_at);

-- ============================================================
-- UNIQUE ORDERING
-- ============================================================

ALTER TABLE agent_execution_events
ADD CONSTRAINT uq_execution_event_sequence
UNIQUE (
    execution_id,
    event_sequence
);

-- ============================================================
-- COMMENT
-- ============================================================

COMMENT ON TABLE agent_execution_events IS
'Stores every event generated during an AI agent execution, providing a complete execution timeline for debugging, auditing and replay.';
