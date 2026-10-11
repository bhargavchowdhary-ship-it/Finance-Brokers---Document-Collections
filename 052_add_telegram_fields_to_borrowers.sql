BEGIN;

-- =====================================================
-- Add Telegram linking fields to borrowers
-- Required by WF-001 Conversation Manager (Telegram channel)
-- =====================================================

ALTER TABLE borrowers
    ADD COLUMN IF NOT EXISTS telegram_chat_id TEXT,
    ADD COLUMN IF NOT EXISTS telegram_link_code TEXT;

-- telegram_chat_id: set once borrower links their Telegram account.
-- Used by WF-001 to resolve inbound messages to a borrower record.
CREATE UNIQUE INDEX IF NOT EXISTS idx_borrowers_telegram_chat_id
ON borrowers(telegram_chat_id)
WHERE telegram_chat_id IS NOT NULL;

-- telegram_link_code: short one-time code the broker shares with the
-- borrower (e.g. via SMS/email at onboarding). Borrower sends this code
-- as their first Telegram message to link their chat_id.
CREATE UNIQUE INDEX IF NOT EXISTS idx_borrowers_telegram_link_code
ON borrowers(telegram_link_code)
WHERE telegram_link_code IS NOT NULL;

COMMENT ON COLUMN borrowers.telegram_chat_id IS
'Telegram chat_id once borrower has linked their account. NULL until linked.';

COMMENT ON COLUMN borrowers.telegram_link_code IS
'One-time code given to borrower at onboarding to link their Telegram chat.';

COMMIT;
