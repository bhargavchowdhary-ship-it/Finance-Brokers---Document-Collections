BEGIN;

TRUNCATE TABLE workflow_steps RESTART IDENTITY CASCADE;

INSERT INTO workflow_steps
(
    workflow_definition_id,
    workflow_stage_id,
    ai_agent_id,
    step_code,
    step_name,
    description,
    execution_order,
    is_required,
    allow_parallel,
    stop_on_failure,
    timeout_seconds,
    max_retries,
    retry_delay_seconds,
    step_status,
    configuration,
    input_schema,
    output_schema,
    is_active
)

SELECT
    wd.id,
    ws.id,
    aa.id,
    s.step_code,
    s.step_name,
    s.description,
    s.execution_order,
    s.is_required,
    s.allow_parallel,
    s.stop_on_failure,
    s.timeout_seconds,
    s.max_retries,
    s.retry_delay_seconds,
    'ACTIVE'::workflow_step_status_enum,
    '{}'::jsonb,
    '{}'::jsonb,
    '{}'::jsonb,
    TRUE

FROM workflow_definitions wd

JOIN workflow_stages ws
ON ws.workflow_definition_id = wd.id

JOIN
(
    VALUES

    (
        'INITIALIZATION',
        'CONVERSATION_MANAGER',
        'Conversation Manager',
        'Initiate borrower conversation',
        1,
        TRUE,
        FALSE,
        TRUE,
        300,
        3,
        60,
        'CONVERSATION_MANAGER'
    ),

    (
        'DOCUMENT_COLLECTION',
        'DOCUMENT_INTAKE',
        'Document Intake',
        'Receive borrower documents',
        1,
        TRUE,
        TRUE,
        TRUE,
        900,
        3,
        300,
        'DOCUMENT_INTAKE'
    ),

    (
        'DOCUMENT_PROCESSING',
        'OCR_PROCESSING',
        'OCR Processing',
        'Extract document text',
        1,
        TRUE,
        TRUE,
        TRUE,
        600,
        3,
        120,
        'OCR_AGENT'
    ),

    (
        'DOCUMENT_PROCESSING',
        'DOCUMENT_INTELLIGENCE',
        'Document Intelligence',
        'Extract structured information',
        2,
        TRUE,
        TRUE,
        TRUE,
        600,
        3,
        120,
        'DOCUMENT_INTELLIGENCE'
    ),

    (
        'DOCUMENT_VERIFICATION',
        'DOCUMENT_VERIFICATION',
        'Document Verification',
        'Verify extracted information',
        1,
        TRUE,
        TRUE,
        TRUE,
        600,
        3,
        120,
        'VERIFICATION_AGENT'
    ),

    (
        'DOCUMENT_VERIFICATION',
        'CROSS_VALIDATION',
        'Cross Validation',
        'Cross validate all extracted information',
        2,
        TRUE,
        TRUE,
        TRUE,
        600,
        3,
        120,
        'CROSS_VALIDATION_AGENT'
    ),

    (
        'APPLICATION_REVIEW',
        'DECISION_ENGINE',
        'Decision Engine',
        'Prepare decision package',
        1,
        TRUE,
        FALSE,
        TRUE,
        300,
        2,
        60,
        'DECISION_AGENT'
    ),

    (
        'APPLICATION_REVIEW',
        'BROKER_REVIEW',
        'Broker Review',
        'Broker reviews application',
        2,
        TRUE,
        FALSE,
        TRUE,
        7200,
        1,
        0,
        NULL
    ),

    (
        'APPLICATION_SUBMISSION',
        'APPLICATION_SUBMISSION',
        'Application Submission',
        'Submit application',
        1,
        TRUE,
        FALSE,
        TRUE,
        900,
        2,
        120,
        NULL
    )

) AS s
(
    stage_code,
    step_code,
    step_name,
    description,
    execution_order,
    is_required,
    allow_parallel,
    stop_on_failure,
    timeout_seconds,
    max_retries,
    retry_delay_seconds,
    agent_code
)
ON TRUE

LEFT JOIN ai_agents aa
    ON aa.agent_code = s.agent_code

WHERE
    wd.workflow_code = 'LOAN_PROCESSING'
    AND ws.stage_code = s.stage_code;

COMMIT;