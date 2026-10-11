BEGIN;

-- =====================================================
-- Allow workflow_events to be logged before a formal
-- workflow_execution row exists.
--
-- WF-001 (Conversation Manager) publishes DOCUMENT_UPLOADED
-- events as soon as a borrower sends a file. At that point
-- there's a workflow_instance (the application is "in" a
-- workflow) but not yet a workflow_execution (that's created
-- later, when WF-004/Workflow Manager actually runs a step).
--
-- workflow_definition_id stays required — we always have it
-- via workflow_instances.workflow_definition_id.
-- =====================================================

ALTER TABLE workflow_events
    ALTER COLUMN workflow_execution_id DROP NOT NULL;

COMMENT ON COLUMN workflow_events.workflow_execution_id IS
'Set once a formal workflow execution picks up this event. NULL for events logged before execution starts (e.g. a raw document upload).';

COMMIT;
