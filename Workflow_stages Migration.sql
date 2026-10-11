BEGIN;

-- ============================================================
-- ENUM : Workflow Stage Type
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typname = 'workflow_stage_type_enum'
    ) THEN

        CREATE TYPE workflow_stage_type_enum AS ENUM
        (
            'HUMAN',
            'AI',
            'SYSTEM'
        );

    END IF;
END $$;

-- ============================================================
-- TABLE : workflow_stages
-- ============================================================

CREATE TABLE workflow_stages
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_definition_id UUID NOT NULL,

    stage_code VARCHAR(100) NOT NULL,

    stage_name VARCHAR(255) NOT NULL,

    stage_order INTEGER NOT NULL
        CHECK (stage_order > 0),

    description TEXT,

    stage_type workflow_stage_type_enum
        NOT NULL,

    allow_parallel BOOLEAN
        NOT NULL
        DEFAULT FALSE,

    expected_duration_minutes INTEGER
        CHECK (expected_duration_minutes IS NULL
            OR expected_duration_minutes >= 0),

    is_active BOOLEAN
        NOT NULL
        DEFAULT TRUE,

    metadata JSONB
        NOT NULL
        DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    updated_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    CONSTRAINT fk_workflow_stage_definition
        FOREIGN KEY(workflow_definition_id)
        REFERENCES workflow_definitions(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT uq_workflow_stage_code
        UNIQUE(workflow_definition_id, stage_code),

    CONSTRAINT uq_workflow_stage_order
        UNIQUE(workflow_definition_id, stage_order)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_workflow_stage_definition
ON workflow_stages(workflow_definition_id);

CREATE INDEX idx_workflow_stage_code
ON workflow_stages(stage_code);

CREATE INDEX idx_workflow_stage_order
ON workflow_stages(stage_order);

CREATE INDEX idx_workflow_stage_type
ON workflow_stages(stage_type);

CREATE INDEX idx_workflow_stage_active
ON workflow_stages(is_active);

CREATE INDEX idx_workflow_stage_metadata
ON workflow_stages
USING GIN(metadata);

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_workflow_stages_updated_at
BEFORE UPDATE
ON workflow_stages
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE workflow_stages IS
'Defines the ordered business stages that make up a workflow template.';

COMMENT ON COLUMN workflow_stages.stage_code IS
'Stable identifier used by automation and application logic.';

COMMENT ON COLUMN workflow_stages.stage_order IS
'Execution order within the workflow definition.';

COMMENT ON COLUMN workflow_stages.stage_type IS
'HUMAN, AI or SYSTEM owned stage.';

COMMENT ON COLUMN workflow_stages.allow_parallel IS
'Indicates whether this stage supports parallel execution.';

COMMENT ON COLUMN workflow_stages.expected_duration_minutes IS
'Expected SLA duration for the stage.';

COMMIT;