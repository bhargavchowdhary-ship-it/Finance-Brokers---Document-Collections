-- ==========================================================
-- Migration : 003_create_borrowers.sql
-- Purpose   : Create borrowers table
-- ==========================================================

CREATE TABLE public.borrowers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    broker_id UUID NOT NULL,

    first_name TEXT NOT NULL,

    last_name TEXT,

    email TEXT NOT NULL,

    phone TEXT NOT NULL,

    date_of_birth DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_borrowers_broker
        FOREIGN KEY (broker_id)
        REFERENCES public.brokers(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE INDEX idx_borrowers_broker_id
ON public.borrowers(broker_id);

CREATE TRIGGER trg_borrowers_updated_at
BEFORE UPDATE
ON public.borrowers
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.borrowers IS
'Stores borrower identity and contact information.';

