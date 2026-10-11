BEGIN;

-- ============================================================
-- TABLE : workflow_definitions
-- ============================================================

CREATE TABLE workflow_definitions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_code VARCHAR(100) NOT NULL,

    workflow_name VARCHAR(255) NOT NULL,

    version INTEGER
        NOT NULL
        DEFAULT 1,

    description TEXT,

    is_active BOOLEAN
        NOT NULL
        DEFAULT TRUE,

    initial_stage VARCHAR(100) NOT NULL,

    initial_step VARCHAR(150) NOT NULL,

    estimated_step_count INTEGER
        NOT NULL
        DEFAULT 0
        CHECK (estimated_step_count >= 0),

    metadata JSONB
        NOT NULL
        DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    updated_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    CONSTRAINT uq_workflow_definition
        UNIQUE(workflow_code, version)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_workflow_definition_code
ON workflow_definitions(workflow_code);

CREATE INDEX idx_workflow_definition_active
ON workflow_definitions(is_active);

CREATE INDEX idx_workflow_definition_version
ON workflow_definitions(version);

CREATE INDEX idx_workflow_definition_metadata
ON workflow_definitions
USING GIN(metadata);

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_workflow_definitions_updated_at
BEFORE UPDATE
ON workflow_definitions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE workflow_definitions IS
'Stores reusable workflow templates used to create workflow instances.';

COMMENT ON COLUMN workflow_definitions.workflow_code IS
'Unique business identifier for the workflow template.';

COMMENT ON COLUMN workflow_definitions.workflow_name IS
'Human-readable workflow name displayed in dashboards.';

COMMENT ON COLUMN workflow_definitions.version IS
'Version number of the workflow template.';

COMMENT ON COLUMN workflow_definitions.initial_stage IS
'Stage where new workflow instances begin.';

COMMENT ON COLUMN workflow_definitions.initial_step IS
'First executable step of the workflow.';

COMMENT ON COLUMN workflow_definitions.metadata IS
'Extensible JSON configuration for workflow behaviour.';

COMMIT;