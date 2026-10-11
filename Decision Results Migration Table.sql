-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE decision_status_enum AS ENUM (
    'APPROVED',
    'DECLINED',
    'MANUAL_REVIEW',
    'MORE_DOCUMENTS_REQUIRED',
    'PENDING'
);

-- ============================================================
-- DECISION RESULTS TABLE
-- ============================================================

CREATE TABLE decision_results (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    application_id UUID NOT NULL,

    final_decision decision_status_enum NOT NULL,

    confidence_score NUMERIC(5,2)
        CHECK (confidence_score >= 0 AND confidence_score <= 100),

    decision_reason TEXT,

    ai_provider VARCHAR(100),

    ai_model VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_decision_application
        FOREIGN KEY (application_id)
        REFERENCES loan_applications(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_decision_application
ON decision_results(application_id);

CREATE INDEX idx_decision_status
ON decision_results(final_decision);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE TRIGGER trg_decision_updated_at

BEFORE UPDATE

ON decision_results

FOR EACH ROW

EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE decision_results IS
'Stores the final AI decision for each mortgage application after document intelligence, verification and cross-validation.';
