-- ============================================================
-- MIGRATION 016
-- Create Conversation Sessions
-- ============================================================

CREATE TABLE conversation_sessions (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    application_id UUID NOT NULL,

    session_identifier TEXT,

    channel TEXT NOT NULL CHECK (
        channel IN (
            'WHATSAPP',
            'EMAIL',
            'SMS',
            'VOICE',
            'TELEGRAM',
            'WEBCHAT'
        )
    ),

    session_status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (
        session_status IN (
            'ACTIVE',
            'WAITING_FOR_CUSTOMER',
            'WAITING_FOR_BROKER',
            'COMPLETED',
            'CLOSED',
            'FAILED'
        )
    ),

    initiated_by TEXT NOT NULL CHECK (
        initiated_by IN (
            'BORROWER',
            'BROKER',
            'AI_AGENT',
            'SYSTEM'
        )
    ),

    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    last_message_at TIMESTAMPTZ,

    ended_at TIMESTAMPTZ,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_conversation_sessions_application
        FOREIGN KEY (application_id)
        REFERENCES loan_applications(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_conversation_sessions_application
ON conversation_sessions(application_id);

CREATE INDEX idx_conversation_sessions_status
ON conversation_sessions(session_status);

CREATE INDEX idx_conversation_sessions_channel
ON conversation_sessions(channel);

CREATE INDEX idx_conversation_sessions_last_message
ON conversation_sessions(last_message_at DESC);

CREATE INDEX idx_conversation_sessions_started
ON conversation_sessions(started_at DESC);

CREATE INDEX idx_conversation_sessions_metadata
ON conversation_sessions
USING GIN(metadata);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE TRIGGER trg_conversation_sessions_updated_at
BEFORE UPDATE
ON conversation_sessions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE conversation_sessions IS
'Represents a logical communication session for a loan application across WhatsApp, Email, SMS, Voice or other channels.';






-- ============================================================
-- MIGRATION 017
-- Link Messages to Conversation Sessions
-- ============================================================

ALTER TABLE messages
ADD COLUMN conversation_session_id UUID;

ALTER TABLE messages
ADD CONSTRAINT fk_messages_conversation_session
FOREIGN KEY (conversation_session_id)
REFERENCES conversation_sessions(id)
ON UPDATE CASCADE
ON DELETE SET NULL;

CREATE INDEX idx_messages_conversation_session
ON messages(conversation_session_id);
