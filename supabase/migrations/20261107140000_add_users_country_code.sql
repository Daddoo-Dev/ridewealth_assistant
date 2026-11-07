-- Country chosen on the account. The app uses it for the currency name,
-- symbol, and whether distance is shown in miles or kilometers.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS "countryCode" TEXT;
