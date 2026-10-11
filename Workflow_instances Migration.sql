BEGIN;

-- ============================================================
-- ENUM : Workflow Status
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typname = 'workflow_status_enum'
    ) THEN

        CREATE TYPE workflow_status_enum AS ENUM
        (
            'CREATED',
            'RUNNING',
            'WAITING',
            'PAUSED',
            'FAILED',
            'COMPLETED',
            'CANCELLED'
        );

    END IF;
END $$;

-- ============================================================
-- TABLE : workflow_instances
-- ============================================================

CREATE TABLE workflow_instances
(

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    application_id UUID NOT NULL,

    workflow_name VARCHAR(100) NOT NULL,

    workflow_version INTEGER
        NOT NULL
        DEFAULT 1,

    current_stage VARCHAR(100) NOT NULL,

    current_step VARCHAR(150) NOT NULL,

    workflow_status workflow_status_enum
        NOT NULL
        DEFAULT 'CREATED',

    progress_percentage NUMERIC(5,2)
        NOT NULL
        DEFAULT 0
        CHECK (
            progress_percentage >= 0
            AND
            progress_percentage <= 100
        ),

    started_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    completed_at TIMESTAMPTZ,

    last_activity_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    failure_reason TEXT,

    metadata JSONB
        NOT NULL
        DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    updated_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    CONSTRAINT fk_workflow_application
        FOREIGN KEY(application_id)
        REFERENCES loan_applications(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT uq_application_workflow
        UNIQUE(application_id, workflow_name)

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_workflow_application
ON workflow_instances(application_id);

CREATE INDEX idx_workflow_name
ON workflow_instances(workflow_name);

CREATE INDEX idx_workflow_status
ON workflow_instances(workflow_status);

CREATE INDEX idx_workflow_stage
ON workflow_instances(current_stage);

CREATE INDEX idx_workflow_last_activity
ON workflow_instances(last_activity_at DESC);

CREATE INDEX idx_workflow_metadata
ON workflow_instances
USING GIN(metadata);

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_workflow_instances_updated_at
BEFORE UPDATE
ON workflow_instances
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE workflow_instances IS
'Represents one running business workflow for a mortgage loan application.';

COMMENT ON COLUMN workflow_instances.workflow_name IS
'Business workflow being executed (Loan Processing, Post Settlement, etc.).';

COMMENT ON COLUMN workflow_instances.current_stage IS
'High level workflow stage.';

COMMENT ON COLUMN workflow_instances.current_step IS
'Detailed workflow step currently executing.';

COMMENT ON COLUMN workflow_instances.progress_percentage IS
'Overall workflow completion percentage.';

COMMENT ON COLUMN workflow_instances.metadata IS
'Workflow specific runtime information stored as JSONB.';

COMMIT;