BEGIN;

-- ============================================================
-- 1. ENUM
-- ============================================================

CREATE TYPE intelligence_status_enum AS ENUM (
    'PENDING',
    'PROCESSING',
    'COMPLETED',
    'FAILED'
);

-- ============================================================
-- 2. TABLE
-- ============================================================

CREATE TABLE document_intelligence_results (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    document_id UUID NOT NULL,

    document_version_id UUID NOT NULL,

    ocr_result_id UUID NOT NULL UNIQUE,

    ai_provider VARCHAR(100) NOT NULL,

    ai_model VARCHAR(150) NOT NULL,

    extracted_fields JSONB NOT NULL,

    confidence_score NUMERIC(5,2),

    processing_time_ms INTEGER,

    intelligence_status intelligence_status_enum NOT NULL DEFAULT 'PENDING',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_intelligence_document
        FOREIGN KEY (document_id)
        REFERENCES documents(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_intelligence_document_version
        FOREIGN KEY (document_version_id)
        REFERENCES document_versions(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_intelligence_ocr
        FOREIGN KEY (ocr_result_id)
        REFERENCES ocr_results(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_confidence
        CHECK (
            confidence_score IS NULL
            OR
            confidence_score BETWEEN 0 AND 100
        )

);

-- ============================================================
-- 3. INDEXES
-- ============================================================

CREATE INDEX idx_intelligence_document
ON document_intelligence_results(document_id);

CREATE INDEX idx_intelligence_document_version
ON document_intelligence_results(document_version_id);

CREATE INDEX idx_intelligence_status
ON document_intelligence_results(intelligence_status);

CREATE INDEX idx_intelligence_json
ON document_intelligence_results
USING GIN(extracted_fields);

-- ============================================================
-- 4. TRIGGER
-- ============================================================

CREATE TRIGGER trg_document_intelligence_updated_at

BEFORE UPDATE
ON document_intelligence_results

FOR EACH ROW

EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 5. COMMENTS
-- ============================================================

COMMENT ON TABLE document_intelligence_results IS
'Structured business fields extracted by the AI Document Intelligence Agent.';

COMMENT ON COLUMN document_intelligence_results.extracted_fields IS
'JSONB containing structured fields extracted from the document.';

COMMENT ON COLUMN document_intelligence_results.ocr_result_id IS
'Links this AI extraction to the OCR result it was generated from.';

COMMENT ON COLUMN document_intelligence_results.confidence_score IS
'Overall confidence assigned by the AI extraction process.';

COMMIT;
