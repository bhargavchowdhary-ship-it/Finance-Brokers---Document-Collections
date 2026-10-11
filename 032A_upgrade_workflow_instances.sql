BEGIN;

-- ============================================================
-- 1. Rename application_id
-- ============================================================

ALTER TABLE workflow_instances
RENAME COLUMN application_id TO loan_application_id;

-- ============================================================
-- 2. Add workflow_definition_id
-- ============================================================

ALTER TABLE workflow_instances
ADD COLUMN workflow_definition_id UUID;

-- ============================================================
-- 3. Add borrower_id
-- ============================================================

ALTER TABLE workflow_instances
ADD COLUMN borrower_id UUID;

-- ============================================================
-- 4. Backfill workflow_definition_id
-- ============================================================

UPDATE workflow_instances wi
SET workflow_definition_id = wd.id
FROM workflow_definitions wd
WHERE wd.workflow_code = wi.workflow_name
AND wd.version = wi.workflow_version;

-- ============================================================
-- 5. Verify no NULLs remain
-- ============================================================

DO $$
DECLARE
    v_missing INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_missing
    FROM workflow_instances
    WHERE workflow_definition_id IS NULL;

    IF v_missing > 0 THEN
        RAISE EXCEPTION
        'Unable to backfill workflow_definition_id for % workflow_instances.',
        v_missing;
    END IF;
END $$;

-- ============================================================
-- 6. Make NOT NULL
-- ============================================================

ALTER TABLE workflow_instances
ALTER COLUMN workflow_definition_id SET NOT NULL;

-- ============================================================
-- 7. Foreign Keys
-- ============================================================

ALTER TABLE workflow_instances
ADD CONSTRAINT fk_workflow_instance_definition
FOREIGN KEY (workflow_definition_id)
REFERENCES workflow_definitions(id);

ALTER TABLE workflow_instances
ADD CONSTRAINT fk_workflow_instance_application
FOREIGN KEY (loan_application_id)
REFERENCES loan_applications(id);

ALTER TABLE workflow_instances
ADD CONSTRAINT fk_workflow_instance_borrower
FOREIGN KEY (borrower_id)
REFERENCES borrowers(id);

-- ============================================================
-- 8. Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_workflow_instances_definition
ON workflow_instances(workflow_definition_id);

CREATE INDEX IF NOT EXISTS idx_workflow_instances_application
ON workflow_instances(loan_application_id);

CREATE INDEX IF NOT EXISTS idx_workflow_instances_borrower
ON workflow_instances(borrower_id);

COMMENT ON COLUMN workflow_instances.workflow_definition_id
IS 'Reference to workflow catalog definition.';

COMMIT;