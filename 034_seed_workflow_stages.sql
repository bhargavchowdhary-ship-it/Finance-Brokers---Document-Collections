BEGIN;

TRUNCATE TABLE workflow_stages RESTART IDENTITY CASCADE;

INSERT INTO workflow_stages
(
    workflow_definition_id,
    stage_code,
    stage_name,
    stage_order,
    stage_type,
    allow_parallel,
    expected_duration_minutes,
    is_active,
    metadata
)
SELECT
    wd.id,
    s.stage_code,
    s.stage_name,
    s.stage_order,
    s.stage_type,
    s.allow_parallel,
    s.expected_duration_minutes,
    TRUE,
    '{}'::jsonb
FROM workflow_definitions wd
CROSS JOIN
(
    VALUES
        ('INITIALIZATION',         'Initialization',          1, 'SYSTEM'::workflow_stage_type_enum, FALSE,    5),
('DOCUMENT_COLLECTION',    'Document Collection',     2, 'HUMAN'::workflow_stage_type_enum, FALSE, 1440),
('DOCUMENT_PROCESSING',    'Document Processing',     3, 'AI'::workflow_stage_type_enum,     TRUE,    60),
('DOCUMENT_VERIFICATION',  'Document Verification',   4, 'AI'::workflow_stage_type_enum,     TRUE,    60),
('APPLICATION_REVIEW',     'Application Review',      5, 'HUMAN'::workflow_stage_type_enum, FALSE,  120),
('APPLICATION_SUBMISSION', 'Application Submission',  6, 'SYSTEM'::workflow_stage_type_enum, FALSE,   30),
('POST_SUBMISSION',        'Post Submission',         7, 'SYSTEM'::workflow_stage_type_enum, FALSE,   15),
('COMPLETED',              'Completed',               8, 'SYSTEM'::workflow_stage_type_enum, FALSE,    1)
) AS s
(
    stage_code,
    stage_name,
    stage_order,
    stage_type,
    allow_parallel,
    expected_duration_minutes
)
WHERE wd.workflow_code = 'WF_001';

COMMIT;