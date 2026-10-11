BEGIN;

-- ============================================================
-- ENUM : execution_backoff_strategy_enum
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM pg_type
        WHERE typname = 'execution_backoff_strategy_enum'
    ) THEN

        CREATE TYPE execution_backoff_strategy_enum AS ENUM
        (
            'FIXED',
            'LINEAR',
            'EXPONENTIAL'
        );

    END IF;
END $$;

-- ============================================================
-- TABLE : execution_policies
-- ============================================================

CREATE TABLE IF NOT EXISTS execution_policies
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_code VARCHAR(100) NOT NULL,
    policy_name VARCHAR(200) NOT NULL,

    description TEXT,

    max_attempts INTEGER NOT NULL DEFAULT 3,

    initial_delay_seconds INTEGER NOT NULL DEFAULT 60,

    backoff_strategy execution_backoff_strategy_enum
        NOT NULL DEFAULT 'FIXED',

    backoff_multiplier NUMERIC(5,2)
        NOT NULL DEFAULT 2.00,

    max_delay_seconds INTEGER
        NOT NULL DEFAULT 600,

    timeout_seconds INTEGER
        NOT NULL DEFAULT 300,

    enable_circuit_breaker BOOLEAN
        NOT NULL DEFAULT FALSE,

    circuit_breaker_threshold INTEGER,

    enable_dead_letter_queue BOOLEAN
        NOT NULL DEFAULT FALSE,

    escalate_after_failure BOOLEAN
        NOT NULL DEFAULT FALSE,

    escalation_agent_id UUID,

    retryable_error_codes JSONB
        NOT NULL DEFAULT '[]'::jsonb,

    configuration JSONB
        NOT NULL DEFAULT '{}'::jsonb,

    is_active BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ
        NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_execution_policy_code
        UNIQUE(policy_code),

    CONSTRAINT fk_execution_policy_agent
        FOREIGN KEY (escalation_agent_id)
        REFERENCES ai_agents(id),

    CONSTRAINT chk_execution_policy_attempts
        CHECK(max_attempts >= 0),

    CONSTRAINT chk_execution_policy_delay
        CHECK(initial_delay_seconds >= 0),

    CONSTRAINT chk_execution_policy_timeout
        CHECK(timeout_seconds > 0),

    CONSTRAINT chk_execution_policy_multiplier
        CHECK(backoff_multiplier >= 1.00),

    CONSTRAINT chk_execution_policy_max_delay
        CHECK(max_delay_seconds >= initial_delay_seconds)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_execution_policy_active
ON execution_policies(is_active);

CREATE INDEX IF NOT EXISTS idx_execution_policy_strategy
ON execution_policies(backoff_strategy);

CREATE INDEX IF NOT EXISTS idx_execution_policy_agent
ON execution_policies(escalation_agent_id);

CREATE INDEX IF NOT EXISTS idx_execution_policy_configuration
ON execution_policies
USING GIN(configuration);

CREATE INDEX IF NOT EXISTS idx_execution_policy_retry_codes
ON execution_policies
USING GIN(retryable_error_codes);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

DROP TRIGGER IF EXISTS trg_execution_policies_updated_at
ON execution_policies;

CREATE TRIGGER trg_execution_policies_updated_at
BEFORE UPDATE
ON execution_policies
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE execution_policies IS
'Reusable execution behaviour shared across Workflow Steps and Workflow Transitions.';

COMMENT ON COLUMN execution_policies.configuration IS
'Future execution options stored as JSON.';

COMMENT ON COLUMN execution_policies.retryable_error_codes IS
'List of retryable provider error codes.';

COMMIT;