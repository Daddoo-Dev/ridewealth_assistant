-- Restore Stripe webhook idempotency table (if dropped by mistake).
-- Adjust columns if your webhook code expected a different schema.

CREATE TABLE IF NOT EXISTS public.processed_stripe_events (
  event_id text PRIMARY KEY,
  received_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.processed_stripe_events IS 'Stripe webhook dedupe: one row per evt_… processed.';

CREATE INDEX IF NOT EXISTS idx_processed_stripe_events_received_at
  ON public.processed_stripe_events (received_at DESC);

ALTER TABLE public.processed_stripe_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.processed_stripe_events FROM PUBLIC;
REVOKE ALL ON TABLE public.processed_stripe_events FROM anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.processed_stripe_events TO service_role;
