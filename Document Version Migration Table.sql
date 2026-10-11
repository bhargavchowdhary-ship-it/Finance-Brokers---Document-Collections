BEGIN;

------------------------------------------------------------
-- 1. Create ENUM
------------------------------------------------------------

CREATE TYPE document_version_status_enum AS ENUM
(
    'ACTIVE',
    'SUPERSEDED',
    'DELETED'
);

------------------------------------------------------------
-- 2. Create Table
------------------------------------------------------------

CREATE TABLE document_versions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    document_id UUID NOT NULL,

    version_number INTEGER NOT NULL,

    storage_path TEXT NOT NULL,

    original_filename TEXT NOT NULL,

    mime_type TEXT NOT NULL,

    file_size_bytes BIGINT NOT NULL,

    file_hash TEXT NOT NULL,

    uploaded_by TEXT NOT NULL DEFAULT 'BORROWER',

    version_status document_version_status_enum
        NOT NULL
        DEFAULT 'ACTIVE',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_document_versions_document
        FOREIGN KEY (document_id)
        REFERENCES documents(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_document_version
        UNIQUE(document_id, version_number)
);

------------------------------------------------------------
-- 3. Indexes
------------------------------------------------------------

CREATE INDEX idx_document_versions_document
ON document_versions(document_id);

CREATE INDEX idx_document_versions_hash
ON document_versions(file_hash);

CREATE INDEX idx_document_versions_status
ON document_versions(version_status);

------------------------------------------------------------
-- 4. Trigger
------------------------------------------------------------

CREATE TRIGGER trg_document_versions_updated_at
BEFORE UPDATE
ON document_versions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

------------------------------------------------------------
-- 5. Comments
------------------------------------------------------------

COMMENT ON TABLE document_versions IS
'Immutable history of every uploaded version of a document.';

COMMENT ON COLUMN document_versions.version_number IS
'Sequential version number beginning from 1.';

COMMENT ON COLUMN document_versions.version_status IS
'ACTIVE = latest version, SUPERSEDED = replaced, DELETED = soft deleted.';

COMMENT ON COLUMN document_versions.file_hash IS
'SHA256 hash for duplicate detection across versions.';

COMMIT;
