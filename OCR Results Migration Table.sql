BEGIN;

------------------------------------------------------------
-- 1. ENUM
------------------------------------------------------------

CREATE TYPE ocr_status_enum AS ENUM
(
    'PENDING',
    'PROCESSING',
    'COMPLETED',
    'FAILED'
);

------------------------------------------------------------
-- 2. TABLE
------------------------------------------------------------

CREATE TABLE ocr_results
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    document_id UUID NOT NULL,

    document_version_id UUID,

    ocr_provider TEXT NOT NULL,

    provider_job_id TEXT,

    raw_text TEXT,

    extracted_json JSONB,

    confidence_score NUMERIC(5,2),

    page_count INTEGER,

    processing_time_ms INTEGER,

    ocr_status ocr_status_enum
        NOT NULL
        DEFAULT 'PENDING',

    error_message TEXT,

    started_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_ocr_document
        FOREIGN KEY(document_id)
        REFERENCES documents(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ocr_document_version
        FOREIGN KEY(document_version_id)
        REFERENCES document_versions(id)
        ON DELETE SET NULL
);

------------------------------------------------------------
-- 3. INDEXES
------------------------------------------------------------

CREATE INDEX idx_ocr_document
ON ocr_results(document_id);

CREATE INDEX idx_ocr_version
ON ocr_results(document_version_id);

CREATE INDEX idx_ocr_status
ON ocr_results(ocr_status);

CREATE INDEX idx_ocr_json
ON ocr_results
USING GIN(extracted_json);

------------------------------------------------------------
-- 4. TRIGGER
------------------------------------------------------------

CREATE TRIGGER trg_ocr_results_updated_at
BEFORE UPDATE
ON ocr_results
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

------------------------------------------------------------
-- 5. COMMENTS
------------------------------------------------------------

COMMENT ON TABLE ocr_results IS
'OCR output generated from uploaded documents.';

COMMENT ON COLUMN ocr_results.raw_text IS
'Complete OCR text extracted from document.';

COMMENT ON COLUMN ocr_results.extracted_json IS
'Structured OCR output returned by OCR provider.';

COMMENT ON COLUMN ocr_results.confidence_score IS
'Overall OCR confidence percentage.';

COMMENT ON COLUMN ocr_results.processing_time_ms IS
'End-to-end OCR execution time.';

COMMIT;
