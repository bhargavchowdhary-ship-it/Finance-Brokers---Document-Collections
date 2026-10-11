BEGIN;

-- =====================================================
-- WORKFLOW INSTANCES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_wi_status
ON workflow_instances(workflow_status);

CREATE INDEX IF NOT EXISTS idx_wi_stage
ON workflow_instances(current_stage);

CREATE INDEX IF NOT EXISTS idx_wi_step
ON workflow_instances(current_step);

CREATE INDEX IF NOT EXISTS idx_wi_activity
ON workflow_instances(last_activity_at DESC);

CREATE INDEX IF NOT EXISTS idx_wi_started
ON workflow_instances(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_wi_definition
ON workflow_instances(workflow_definition_id);

CREATE INDEX IF NOT EXISTS idx_wi_borrower
ON workflow_instances(borrower_id);

CREATE INDEX IF NOT EXISTS idx_wi_application
ON workflow_instances(loan_application_id);

-- =====================================================
-- WORKFLOW EXECUTIONS
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_we_instance
ON workflow_executions(workflow_instance_id);

CREATE INDEX IF NOT EXISTS idx_we_status
ON workflow_executions(status);

CREATE INDEX IF NOT EXISTS idx_we_started
ON workflow_executions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_we_completed
ON workflow_executions(completed_at DESC);

CREATE INDEX IF NOT EXISTS idx_we_execution_number
ON workflow_executions(workflow_instance_id, execution_number DESC);

-- =====================================================
-- STEP EXECUTIONS
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_wse_execution
ON workflow_step_executions(workflow_execution_id);

CREATE INDEX IF NOT EXISTS idx_wse_step
ON workflow_step_executions(workflow_step_id);

CREATE INDEX IF NOT EXISTS idx_wse_status
ON workflow_step_executions(step_status);

CREATE INDEX IF NOT EXISTS idx_wse_started
ON workflow_step_executions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_wse_completed
ON workflow_step_executions(completed_at DESC);

CREATE INDEX IF NOT EXISTS idx_wse_execution_step
ON workflow_step_executions(
    workflow_execution_id,
    workflow_step_id
);

-- =====================================================
-- WORKFLOW EVENTS
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_events_status
ON workflow_events(status);

CREATE INDEX IF NOT EXISTS idx_events_type
ON workflow_events(event_type);

CREATE INDEX IF NOT EXISTS idx_events_created
ON workflow_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_events_dispatch
ON workflow_events(status, created_at);

CREATE INDEX IF NOT EXISTS idx_events_correlation
ON workflow_events(correlation_id);

CREATE INDEX IF NOT EXISTS idx_events_causation
ON workflow_events(causation_id);

CREATE INDEX IF NOT EXISTS idx_events_instance
ON workflow_events(workflow_instance_id);

CREATE INDEX IF NOT EXISTS idx_events_execution
ON workflow_events(workflow_execution_id);

-- =====================================================
-- WORKFLOW STEPS
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_steps_definition
ON workflow_steps(workflow_definition_id);

CREATE INDEX IF NOT EXISTS idx_steps_stage
ON workflow_steps(workflow_stage_id);

CREATE INDEX IF NOT EXISTS idx_steps_execution_order
ON workflow_steps(
    workflow_definition_id,
    execution_order
);

CREATE INDEX IF NOT EXISTS idx_steps_code
ON workflow_steps(step_code);

-- =====================================================
-- TRANSITIONS
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_transition_from
ON workflow_transitions(from_stage_id);

CREATE INDEX IF NOT EXISTS idx_transition_to
ON workflow_transitions(to_stage_id);

CREATE INDEX IF NOT EXISTS idx_transition_default
ON workflow_transitions(is_default);

CREATE INDEX IF NOT EXISTS idx_transition_priority
ON workflow_transitions(priority);

CREATE INDEX IF NOT EXISTS idx_transition_event
ON workflow_transitions(event_name);

COMMIT;