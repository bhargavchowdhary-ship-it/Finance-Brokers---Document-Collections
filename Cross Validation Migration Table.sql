-- ============================================================
-- CROSS VALIDATION RESULTS
-- ============================================================

CREATE TYPE cross_validation_status_enum AS ENUM (
    'MATCH',
    'MISMATCH',
    'MISSING',
    'PARTIAL_MATCH',
    'NOT_APPLICABLE'
);

CREATE TABLE cross_validation_results (

    id UUID PRIMARY KEY
        DEFAULT gen_random_uuid(),

    loan_application_id UUID NOT NULL,

    document_intelligence_result_1_id UUID NOT NULL,

    document_intelligence_result_2_id UUID NOT NULL,

    field_name TEXT NOT NULL,

    value_1 TEXT,

    value_2 TEXT,

    validation_status cross_validation_status_enum NOT NULL,

    confidence_score NUMERIC(5,2),

    validation_notes TEXT,

    ai_provider TEXT,

    ai_model TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_cross_validation_application
        FOREIGN KEY (loan_application_id)
        REFERENCES loan_applications(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_cross_validation_result_1
        FOREIGN KEY (document_intelligence_result_1_id)
        REFERENCES document_intelligence_results(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_cross_validation_result_2
        FOREIGN KEY (document_intelligence_result_2_id)
        REFERENCES document_intelligence_results(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_cross_validation_application
ON cross_validation_results(loan_application_id);

CREATE INDEX idx_cross_validation_status
ON cross_validation_results(validation_status);

CREATE INDEX idx_cross_validation_doc1
ON cross_validation_results(document_intelligence_result_1_id);

CREATE INDEX idx_cross_validation_doc2
ON cross_validation_results(document_intelligence_result_2_id);

CREATE TRIGGER trg_cross_validation_updated_at
BEFORE UPDATE
ON cross_validation_results
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE cross_validation_results IS
'Stores AI comparison results across multiple mortgage documents.';
