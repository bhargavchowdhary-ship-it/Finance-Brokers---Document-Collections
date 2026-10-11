-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE verification_type_enum AS ENUM (
    'DOCUMENT_AUTHENTICITY',
    'DOCUMENT_EXPIRY',
    'OCR_QUALITY',
    'IDENTITY_MATCH',
    'ADDRESS_MATCH',
    'ABN_VALIDATION',
    'ACN_VALIDATION',
    'BANK_ACCOUNT_VALIDATION',
    'SIGNATURE_VERIFICATION',
    'FRAUD_CHECK'
);

CREATE TYPE verification_status_enum AS ENUM (
    'PENDING',
    'PASSED',
    'FAILED',
    'WARNING',
    'MANUAL_REVIEW'
);

-- =====================================================
-- TABLE
-- =====================================================

CREATE TABLE verification_results (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    application_id UUID NOT NULL,

    intelligence_result_id UUID NOT NULL,

    verification_type verification_type_enum NOT NULL,

    verification_status verification_status_enum NOT NULL DEFAULT 'PENDING',

    confidence_score NUMERIC(5,2),

    verification_message TEXT,

    verified_by TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_verification_application
        FOREIGN KEY (application_id)
        REFERENCES loan_applications(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_verification_intelligence
        FOREIGN KEY (intelligence_result_id)
        REFERENCES document_intelligence_results(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_verification_application
ON verification_results(application_id);

CREATE INDEX idx_verification_intelligence
ON verification_results(intelligence_result_id);

CREATE INDEX idx_verification_status
ON verification_results(verification_status);

CREATE INDEX idx_verification_type
ON verification_results(verification_type);

-- =====================================================
-- UPDATED_AT TRIGGER
-- =====================================================

CREATE TRIGGER trg_verification_updated_at
BEFORE UPDATE
ON verification_results
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- COMMENT
-- =====================================================

COMMENT ON TABLE verification_results
IS 'Stores AI and rule-based verification outcomes for individual mortgage documents.';

