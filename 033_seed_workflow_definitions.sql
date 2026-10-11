-- ============================================================================
-- Migration : 033_seed_workflow_definitions.sql
-- Purpose   : Seed master workflow catalog
-- ============================================================================

BEGIN;

INSERT INTO workflow_definitions
(
    workflow_code,
    workflow_name,
    version,
    description,
    is_active,
    initial_stage,
    initial_step,
    estimated_step_count,
    metadata
)
VALUES
(
    'LOAN_PROCESSING',
    'LOAN_PROCESSING',
    1,
    'Complete end-to-end mortgage loan processing workflow.',
    TRUE,
    'INITIALIZATION',
    'CREATE_WORKFLOW_INSTANCE',
    40,
    '{}'::jsonb
)
ON CONFLICT (workflow_code, version)
DO NOTHING;

COMMIT;