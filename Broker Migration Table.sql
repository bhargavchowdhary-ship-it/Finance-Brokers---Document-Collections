--=========================================
--Migration : 001_create_brokers.sql
--Purpose : Create brokers table
--Author : Bhargav Gavini
--=========================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE TABLE brokers (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
name           TEXT NOT NULL,
company_name   TEXT,
email          TEXT NOT NULL UNIQUE,
phone          TEXT,
license_number TEXT,
timezone       TEXT NOT NULL DEFAULT 'Australia/Sydney',
is_active      BOOLEAN NOT NULL DEFAULT TRUE,
created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE brokers IS
'Stores Mortgage Brokers Information.';
-- ==========================================================
-- Migration : 001_create_brokers.sql
-- Purpose   : Create brokers table with automatic timestamps
-- Author    : Bhargav Gavini
-- ==========================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-------------------------------------------------------------
-- Reusable function to update updated_at automatically
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at_column()

RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------
-- Brokers Table
-------------------------------------------------------------

CREATE TABLE brokers (

    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name             TEXT NOT NULL,

    company_name     TEXT,

    email            TEXT NOT NULL UNIQUE,

    phone            TEXT,

    license_number   TEXT,

    timezone         TEXT NOT NULL DEFAULT 'Australia/Sydney',

    is_active        BOOLEAN NOT NULL DEFAULT TRUE,

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

-------------------------------------------------------------
-- Automatically maintain updated_at
-------------------------------------------------------------

CREATE TRIGGER trg_brokers_updated_at

BEFORE UPDATE

ON brokers

FOR EACH ROW

EXECUTE FUNCTION update_updated_at_column();

-------------------------------------------------------------
-- Documentation
-------------------------------------------------------------

COMMENT ON TABLE brokers IS
'Stores mortgage broker information.';
SELECT
    trigger_name,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE event_object_table = 'brokers';
SELECT routine_name
FROM information_schema.routines
WHERE routine_name = 'update_updated_at_column';

