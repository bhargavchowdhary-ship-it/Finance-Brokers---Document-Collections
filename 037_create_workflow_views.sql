BEGIN;

-- ============================================================
-- View: v_workflow_catalog
-- ============================================================

DROP VIEW IF EXISTS v_workflow_catalog CASCADE;

CREATE VIEW v_workflow_catalog AS
SELECT
    wd.id                               AS workflow_definition_id,
    wd.workflow_code,
    wd.workflow_name,
    wd.version,
    wd.is_active                        AS workflow_active,

    ws.id                               AS workflow_stage_id,
    ws.stage_code,
    ws.stage_name,
    ws.stage_order,
    ws.stage_type,

    st.id                               AS workflow_step_id,
    st.step_code,
    st.step_name,
    st.execution_order,
    st.ai_agent_id,
    aa.agent_name,
    aa.agent_type,

    st.timeout_seconds,
    st.max_retries,
    st.retry_delay_seconds

FROM workflow_definitions wd

JOIN workflow_stages ws
    ON ws.workflow_definition_id = wd.id

JOIN workflow_steps st
    ON st.workflow_stage_id = ws.id

LEFT JOIN ai_agents aa
    ON aa.id = st.ai_agent_id

ORDER BY
    wd.workflow_code,
    ws.stage_order,
    st.execution_order;

COMMENT ON VIEW v_workflow_catalog IS
'Complete workflow catalogue including workflow, stages, steps and AI agents.';


-- ============================================================
-- View: v_workflow_transitions
-- ============================================================

DROP VIEW IF EXISTS v_workflow_transitions CASCADE;

CREATE VIEW v_workflow_transitions AS
SELECT

    wt.id,

    wd.workflow_code,

    fs.stage_code           AS from_stage,

    ts.stage_code           AS to_stage,

    wt.transition_name,

    wt.event_name,

    wt.transition_type,

    wt.priority,

    wt.allow_parallel,

    wt.requires_human_approval,

    wt.is_default,

    ns.step_code            AS next_step_code,

    ns.step_name            AS next_step_name

FROM workflow_transitions wt

JOIN workflow_definitions wd
ON wd.id = wt.workflow_definition_id

JOIN workflow_stages fs
ON fs.id = wt.from_stage_id

JOIN workflow_stages ts
ON ts.id = wt.to_stage_id

LEFT JOIN workflow_steps ns
ON ns.id = wt.next_step_id

ORDER BY
    wd.workflow_code,
    wt.priority;

COMMENT ON VIEW v_workflow_transitions IS
'Workflow transition catalogue.';


-- ============================================================
-- View: v_workflow_execution_summary
-- ============================================================

DROP VIEW IF EXISTS v_workflow_execution_summary CASCADE;

CREATE VIEW v_workflow_execution_summary AS

SELECT

    wi.id                                AS workflow_instance_id,

    wi.application_id,

    wi.workflow_name,

    wi.workflow_version,

    we.id                                AS workflow_execution_id,

    we.execution_number,

    we.status                            AS execution_status,

    we.started_at,

    we.completed_at,

    we.execution_duration_ms,

    wi.current_stage,

    wi.current_step,

    wi.workflow_status,

    wi.progress_percentage,

    wi.last_activity_at,

    wi.failure_reason

FROM workflow_instances wi

LEFT JOIN workflow_executions we
       ON we.workflow_instance_id = wi.id;

COMMENT ON VIEW v_workflow_execution_summary IS
'Live execution summary for workflow instances.';

COMMIT;