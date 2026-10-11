BEGIN;

-- ============================================================
-- ENUM : agent_type_enum
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typname = 'agent_type_enum'
    ) THEN
        CREATE TYPE agent_type_enum AS ENUM
        (
            'AI',
            'SYSTEM'
        );
    END IF;
END $$;

-- ============================================================
-- TABLE : ai_agents
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_agents
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    agent_code VARCHAR(100) NOT NULL,
    agent_name VARCHAR(200) NOT NULL,
    description TEXT,

    agent_type agent_type_enum NOT NULL DEFAULT 'AI',

    ai_provider VARCHAR(100) NOT NULL,
    model_name VARCHAR(100) NOT NULL,

    prompt_version INTEGER NOT NULL DEFAULT 1,

    temperature NUMERIC(3,2) NOT NULL DEFAULT 0.20,

    execution_timeout_seconds INTEGER NOT NULL DEFAULT 120,

    max_retry_count INTEGER NOT NULL DEFAULT 3,

    supports_parallel_execution BOOLEAN NOT NULL DEFAULT FALSE,

    supports_human_override BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_ai_agent_code
        UNIQUE(agent_code),

    CONSTRAINT chk_temperature
        CHECK
        (
            temperature >= 0
            AND temperature <= 2
        ),

    CONSTRAINT chk_timeout
        CHECK(execution_timeout_seconds > 0),

    CONSTRAINT chk_retry
        CHECK(max_retry_count >= 0)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_ai_agents_provider
ON ai_agents(ai_provider);

CREATE INDEX IF NOT EXISTS idx_ai_agents_model
ON ai_agents(model_name);

CREATE INDEX IF NOT EXISTS idx_ai_agents_active
ON ai_agents(is_active);

CREATE INDEX IF NOT EXISTS idx_ai_agents_type
ON ai_agents(agent_type);

CREATE INDEX IF NOT EXISTS idx_ai_agents_metadata
ON ai_agents
USING GIN(metadata);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

DROP TRIGGER IF EXISTS trg_ai_agents_updated_at
ON ai_agents;

CREATE TRIGGER trg_ai_agents_updated_at
BEFORE UPDATE
ON ai_agents
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SEED MASTER AGENTS
-- ============================================================

INSERT INTO ai_agents
(
    agent_code,
    agent_name,
    description,
    agent_type,
    ai_provider,
    model_name,
    supports_parallel_execution,
    supports_human_override
)
VALUES

(
'CONVERSATION_MANAGER',
'Conversation Manager',
'Orchestrates borrower conversations and workflow progression.',
'AI',
'OpenAI',
'gpt-5',
FALSE,
TRUE
),

(
'DOCUMENT_INTAKE',
'Document Intake Agent',
'Receives, validates and stores uploaded documents.',
'AI',
'OpenAI',
'gpt-5',
TRUE,
FALSE
),

(
'OCR_AGENT',
'OCR Agent',
'Extracts text from uploaded documents.',
'AI',
'OpenAI',
'gpt-5',
TRUE,
FALSE
),

(
'DOCUMENT_INTELLIGENCE',
'Document Intelligence Agent',
'Extracts structured fields from OCR output.',
'AI',
'OpenAI',
'gpt-5',
TRUE,
FALSE
),

(
'VERIFICATION_AGENT',
'Verification Agent',
'Verifies extracted document information.',
'AI',
'OpenAI',
'gpt-5',
TRUE,
FALSE
),

(
'CROSS_VALIDATION_AGENT',
'Cross Validation Agent',
'Cross validates data across multiple documents.',
'AI',
'OpenAI',
'gpt-5',
TRUE,
FALSE
),

(
'DECISION_AGENT',
'Decision Agent',
'Produces final application assessment.',
'AI',
'OpenAI',
'gpt-5',
FALSE,
TRUE
),

(
'REMINDER_AGENT',
'Reminder Agent',
'Schedules borrower reminders.',
'SYSTEM',
'OpenAI',
'gpt-5',
FALSE,
FALSE
),

(
'NOTIFICATION_AGENT',
'Notification Agent',
'Sends email, SMS and WhatsApp notifications.',
'SYSTEM',
'OpenAI',
'gpt-5',
TRUE,
FALSE
)

ON CONFLICT (agent_code)
DO NOTHING;

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE ai_agents IS
'Master registry of all AI and System agents used by the Mortgage AI Platform.';

COMMENT ON COLUMN ai_agents.prompt_version IS
'Current production prompt version used by the agent.';

COMMENT ON COLUMN ai_agents.metadata IS
'Extensible JSON configuration for future agent capabilities.';

COMMIT;