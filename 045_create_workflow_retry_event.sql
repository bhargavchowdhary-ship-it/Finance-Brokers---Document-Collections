BEGIN;

CREATE OR REPLACE FUNCTION workflow.retry_event
(
    p_event_id UUID,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS
$$
DECLARE
    v_updated INTEGER;
BEGIN

    UPDATE workflow_events
    SET
        event_status = 'PENDING'::event_status_enum,
        processed_at = NULL,
        metadata = COALESCE(metadata,'{}'::jsonb) ||
                   COALESCE(p_metadata,'{}'::jsonb)
    WHERE id = p_event_id
      AND event_status = 'FAILED'::event_status_enum;

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    RETURN v_updated > 0;

END;
$$;

COMMENT ON FUNCTION workflow.retry_event IS
'Moves a FAILED workflow event back to PENDING for re-dispatch.';

COMMIT;