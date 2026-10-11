BEGIN;

-- ============================================================
-- Migration 050
-- Workflow Reporting Views
-- ============================================================

---------------------------------------------------------------
-- Drop existing views if they exist
---------------------------------------------------------------

DROP VIEW IF EXISTS public.v_workflow_instance_summary CASCADE;
DROP VIEW IF EXISTS public.v_step_execution_summary CASCADE;

---------------------------------------------------------------
-- View : Workflow Instance Summary
---------------------------------------------------------------

CREATE VIEW public.v_workflow_instance_summary AS

SELECT

    wi.id                                      AS workflow_instance_id,
    wi.loan_application_id,
    wi.borrower_id,

    wd.id                                      AS workflow_definition_id,
    wd.workflow_code,
    wd.workflow_name,
    wd.version                                 AS workflow_version,

    wi.workflow_status,

    we.id                                      AS workflow_execution_id,
    we.execution_number,
    we.status                                  AS execution_status,

    we.started_at,
    we.completed_at,
    we.execution_duration_ms,

    (
        SELECT COUNT(*)
        FROM workflow_step_executions wse
        WHERE wse.workflow_execution_id = we.id
    )                                          AS total_steps,

    (
        SELECT COUNT(*)
        FROM workflow_step_executions wse
        WHERE wse.workflow_execution_id = we.id
          AND wse.status = 'COMPLETED'
    )                                          AS completed_steps,

    (
        SELECT COUNT(*)
        FROM workflow_step_executions wse
        WHERE wse.workflow_execution_id = we.id
          AND wse.status = 'FAILED'
    )                                          AS failed_steps,

    wi.progress_percentage,
    wi.started_at                              AS workflow_started_at,
    wi.completed_at                            AS workflow_completed_at,
    wi.last_activity_at,
    wi.created_at

FROM workflow_instances wi

JOIN workflow_definitions wd
    ON wd.id = wi.workflow_definition_id

LEFT JOIN workflow_executions we
    ON we.workflow_instance_id = wi.id

WHERE wi.workflow_status IN ('WAITING','RUNNING');

COMMENT ON VIEW public.v_workflow_instance_summary IS
'Live summary of active workflow instances.';

---------------------------------------------------------------
-- View : Step Execution Summary
---------------------------------------------------------------

CREATE VIEW public.v_step_execution_summary AS

SELECT

    wse.id                                   AS workflow_step_execution_id,

    wse.workflow_execution_id,
    wse.workflow_instance_id,

    ws.step_code,
    ws.step_name,

    wse.execution_order,
    wse.attempt_number,

    wse.status,

    wse.started_at,
    wse.completed_at,
    wse.execution_duration_ms,

    wse.ai_agent_execution_id,

    wse.created_at

FROM workflow_step_executions wse

JOIN workflow_steps ws
    ON ws.id = wse.workflow_step_id;

COMMENT ON VIEW public.v_step_execution_summary IS
'Execution summary for workflow step executions.';

COMMIT;