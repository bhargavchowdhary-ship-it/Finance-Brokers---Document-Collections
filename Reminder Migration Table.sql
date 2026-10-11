-- ============================================================
-- MIGRATION 012
-- Create Reminders Table
-- ============================================================

CREATE TABLE reminders (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    application_id UUID NOT NULL,

    reminder_type VARCHAR(100) NOT NULL,

    reminder_reason TEXT,

    scheduled_at TIMESTAMPTZ NOT NULL,

    sent_at TIMESTAMPTZ,

    next_retry_at TIMESTAMPTZ,

    reminder_count INTEGER NOT NULL DEFAULT 0,

    max_reminders INTEGER NOT NULL DEFAULT 5,

    status VARCHAR(30) NOT NULL
        CHECK (
            status IN (
                'PENDING',
                'SCHEDULED',
                'SENT',
                'FAILED',
                'CANCELLED',
                'COMPLETED'
            )
        ),

    channel VARCHAR(30) NOT NULL
        CHECK (
            channel IN (
                'WHATSAPP',
                'EMAIL',
                'SMS',
                'VOICE_CALL'
            )
        ),

    created_by VARCHAR(30) NOT NULL DEFAULT 'AI_AGENT'
        CHECK (
            created_by IN (
                'AI_AGENT',
                'BROKER',
                'SYSTEM'
            )
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_reminders_application
        FOREIGN KEY(application_id)
        REFERENCES loan_applications(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_reminders_application
ON reminders(application_id);

CREATE INDEX idx_reminders_status
ON reminders(status);

CREATE INDEX idx_reminders_schedule
ON reminders(scheduled_at);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE TRIGGER trg_reminders_updated_at

BEFORE UPDATE
ON reminders

FOR EACH ROW

EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE reminders IS
'Stores every scheduled reminder generated during the mortgage application lifecycle.';
