BEGIN;

TRUNCATE TABLE workflow_transitions RESTART IDENTITY CASCADE;

INSERT INTO workflow_transitions
(
    workflow_definition_id,
    from_stage_id,
    to_stage_id,
    next_step_id,
    execution_policy_id,
    transition_name,
    event_name,
    transition_type,
    priority,
    condition_expression,
    metadata,
    success_transition_id,
    failure_transition_id,
    timeout_transition_id,
    rollback_transition_id,
    allow_parallel,
    requires_human_approval,
    is_default,
    is_active
)

SELECT
    wd.id,
    fs.id,
    ts.id,
    ns.id,
    NULL,
    t.transition_name,
    t.event_name,
    t.transition_type::transition_type_enum,
    t.priority,
    '{}'::jsonb,
    '{}'::jsonb,
    NULL,
    NULL,
    NULL,
    NULL,
    FALSE,
    FALSE,
    TRUE,
    TRUE

FROM workflow_definitions wd

JOIN workflow_stages fs
ON fs.workflow_definition_id = wd.id

JOIN workflow_stages ts
ON ts.workflow_definition_id = wd.id

LEFT JOIN workflow_steps ns
ON ns.workflow_stage_id = ts.id
AND ns.execution_order = 1

JOIN
(
VALUES

(
'INITIALIZATION',
'DOCUMENT_COLLECTION',
'Initialization → Document Collection',
'INITIALIZATION_COMPLETED',
'SUCCESS',
1
),

(
'DOCUMENT_COLLECTION',
'DOCUMENT_PROCESSING',
'Document Collection → Document Processing',
'DOCUMENT_COLLECTION_COMPLETED',
'SUCCESS',
2
),

(
'DOCUMENT_PROCESSING',
'DOCUMENT_VERIFICATION',
'Document Processing → Document Verification',
'DOCUMENT_PROCESSING_COMPLETED',
'SUCCESS',
3
),

(
'DOCUMENT_VERIFICATION',
'APPLICATION_REVIEW',
'Document Verification → Application Review',
'DOCUMENT_VERIFICATION_COMPLETED',
'SUCCESS',
4
),

(
'APPLICATION_REVIEW',
'APPLICATION_SUBMISSION',
'Application Review → Application Submission',
'APPLICATION_APPROVED',
'HUMAN_APPROVAL',
5
),

(
'APPLICATION_SUBMISSION',
'POST_SUBMISSION',
'Application Submission → Post Submission',
'APPLICATION_SUBMITTED',
'SUCCESS',
6
),

(
'POST_SUBMISSION',
'COMPLETED',
'Post Submission → Completed',
'WORKFLOW_COMPLETED',
'TERMINAL',
7
)

) t
(
from_stage_code,
to_stage_code,
transition_name,
event_name,
transition_type,
priority
)

ON
     fs.stage_code = t.from_stage_code
AND ts.stage_code = t.to_stage_code

WHERE wd.workflow_code = 'WF_001';

COMMIT;