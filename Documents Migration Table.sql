BEGIN;

-- =====================================================
-- ENUM : Document Processing Status
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typname = 'document_processing_status_enum'
    ) THEN

        CREATE TYPE document_processing_status_enum AS ENUM
        (
            'UPLOADED',
            'PROCESSING',
            'OCR_COMPLETED',
            'VERIFIED',
            'FAILED'
        );

    END IF;
END $$;

-- =====================================================
-- TABLE : documents
-- =====================================================

CREATE TABLE IF NOT EXISTS documents
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    checklist_id UUID NOT NULL,

    original_filename TEXT NOT NULL,

    stored_filename TEXT NOT NULL,

    storage_path TEXT NOT NULL,

    mime_type TEXT NOT NULL,

    file_extension VARCHAR(20) NOT NULL,

    file_size_bytes BIGINT NOT NULL,

    file_hash CHAR(64),

    processing_status document_processing_status_enum
        NOT NULL
        DEFAULT 'UPLOADED',

    is_password_protected BOOLEAN
        NOT NULL
        DEFAULT FALSE,

    uploaded_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    processed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    updated_at TIMESTAMPTZ
        NOT NULL
        DEFAULT NOW(),

    CONSTRAINT fk_documents_checklist
        FOREIGN KEY (checklist_id)
        REFERENCES document_checklists(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =====================================================
-- UNIQUE HASH
-- =====================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_documents_hash
ON documents(file_hash)
WHERE file_hash IS NOT NULL;

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_documents_checklist
ON documents(checklist_id);

CREATE INDEX IF NOT EXISTS idx_documents_status
ON documents(processing_status);

CREATE INDEX IF NOT EXISTS idx_documents_uploaded
ON documents(uploaded_at);

-- =====================================================
-- TRIGGER
-- =====================================================

DROP TRIGGER IF EXISTS trg_documents_updated_at
ON documents;

CREATE TRIGGER trg_documents_updated_at
BEFORE UPDATE
ON documents
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE documents IS
'Stores every uploaded document received from borrowers.';

COMMENT ON COLUMN documents.storage_path IS
'Physical path inside Supabase Storage or S3.';

COMMENT ON COLUMN documents.file_hash IS
'SHA-256 hash used for duplicate detection.';

COMMENT ON COLUMN documents.processing_status IS
'Lifecycle of OCR and AI processing.';

COMMIT;
