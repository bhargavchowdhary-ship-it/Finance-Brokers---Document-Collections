-- ============================================================================
-- Migration: 030_create_workflow_schema.sql
-- Description : Creates the dedicated schema for the Workflow Engine.
-- Author      : Mortgage AI Platform
-- Version     : 1.0
-- ============================================================================

BEGIN;

-- ============================================================================
-- Create Schema
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS workflow;

COMMENT ON SCHEMA workflow IS
'Workflow Engine namespace containing all workflow runtime RPC functions.';

-- ============================================================================
-- Security
-- ============================================================================

REVOKE ALL
ON SCHEMA workflow
FROM PUBLIC;

GRANT USAGE
ON SCHEMA workflow
TO authenticated;

GRANT USAGE
ON SCHEMA workflow
TO service_role;

GRANT CREATE
ON SCHEMA workflow
TO postgres;

-- ============================================================================
-- Default Privileges
-- ============================================================================

ALTER DEFAULT PRIVILEGES
IN SCHEMA workflow
GRANT EXECUTE
ON FUNCTIONS
TO authenticated;

ALTER DEFAULT PRIVILEGES
IN SCHEMA workflow
GRANT EXECUTE
ON FUNCTIONS
TO service_role;

-- ============================================================================
-- Future Proofing
-- ============================================================================

COMMENT ON SCHEMA workflow IS
'Contains all Workflow Engine RPCs including execution, step orchestration, event dispatching, retries and recovery.';

COMMIT;