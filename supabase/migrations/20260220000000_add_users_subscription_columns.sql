-- Add subscription-related columns to users table (used by IAP services and main.dart gate)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS subscription_status TEXT,
  ADD COLUMN IF NOT EXISTS subscription_platform TEXT,
  ADD COLUMN IF NOT EXISTS subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS subscription_expiry TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_updated TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_subscribed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS subscription_type TEXT;

COMMENT ON COLUMN users.subscription_status IS 'active, pending, error, canceled, invalid';
COMMENT ON COLUMN users.subscription_platform IS 'apple or google';
COMMENT ON COLUMN users.last_updated IS 'Last subscription/record update';
