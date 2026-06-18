-- App uses native IAP + RevenueCat only; no Stripe webhooks in this codebase.
-- Drop leftover table if present (clears Security Advisor / unused grants).
DROP TABLE IF EXISTS public.processed_stripe_events CASCADE;
