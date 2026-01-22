# Database Schema Documentation

This document describes the Supabase PostgreSQL database schema and Row Level Security (RLS) policies for the RideWealth Assistant application.

## Tables

### `users`
User profile information and settings.

**Columns:**
- `id` (UUID, PRIMARY KEY, NOT NULL, DEFAULT: `auth.uid()`) - User ID matching Supabase Auth user ID
- `email` (TEXT, NOT NULL) - User's email address
- `phone` (TEXT, NULLABLE) - User's phone number
- `address` (TEXT, NULLABLE) - Street address
- `city` (TEXT, NULLABLE) - City
- `state` (TEXT, NULLABLE) - State
- `zip` (TEXT, NULLABLE) - ZIP code
- `subscription_start_date` (TIMESTAMPTZ, NULLABLE) - When user's subscription started
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT: `now() AT TIME ZONE 'utc'`) - Account creation timestamp
- `federalrate` (NUMERIC, NULLABLE) - User's federal tax rate
- `staterate` (NUMERIC, NULLABLE) - User's state tax rate
- `custommileagerate` (NUMERIC, NULLABLE) - Custom mileage rate override

**RLS Policies:**
- **Users can insert their own row** (INSERT)
  - `WITH CHECK (id = auth.uid())`
  - Allows users to create their own user document during signup
  
- **Users can select their own row** (SELECT)
  - `USING (id = auth.uid())`
  - Users can only read their own user data
  
- **Users can update their own row** (UPDATE)
  - `USING (id = auth.uid())` AND `WITH CHECK (id = auth.uid())`
  - Users can only update their own user data

**Notes:**
- RLS is enabled
- The `id` column defaults to `auth.uid()` ensuring it matches the authenticated user's ID
- User document is created automatically on first sign-in via `createSupabaseUserDocument()`

---

### `feature_flags`
Feature flags for controlling application behavior.

**Columns:**
- (Structure inferred from code usage - exact schema not in migrations)
- Used by `FeatureFlags.initialize()` to fetch flags from Supabase
- Flags include: `subscriptions_enabled`, `subscription_check_enabled`, `subscription_required_screen_enabled`, `store_redirect_enabled`

**Notes:**
- Referenced in `lib/services/feature_flag_service.dart`
- Falls back to defaults if Supabase is unreachable
- No RLS policies documented (may be public read or service_role only)

---

### `income`
Income records for tracking earnings.

**Columns:**
- (Structure inferred from code usage)
- Referenced in: `lib/screens/income_screen.dart`, `lib/screens/export_screen.dart`, `lib/screens/tax_estimates.dart`
- Likely includes: `id`, `user_id`, `date`, `amount`, `source`, `description`, `notes`, `created_at`

**Notes:**
- RLS policies not documented in migrations
- Should have policies allowing users to CRUD their own income records

---

### `expenses`
Expense records for tracking business expenditures.

**Columns:**
- (Structure inferred from code usage)
- Referenced in: `lib/screens/expenses_screen.dart`, `lib/screens/export_screen.dart`, `lib/screens/tax_estimates.dart`
- Likely includes: `id`, `user_id`, `date`, `amount`, `category`, `description`, `notes`, `created_at`

**Notes:**
- RLS policies not documented in migrations
- Should have policies allowing users to CRUD their own expense records

---

### `mileage`
Mileage tracking records for tax deductions.

**Columns:**
- (Structure inferred from code usage)
- Referenced in: `lib/screens/mileage_screen.dart`, `lib/screens/export_screen.dart`, `lib/screens/tax_estimates.dart`
- Likely includes: `id`, `user_id`, `start_date`, `start_mileage`, `end_mileage`, `notes`, `created_at`

**Notes:**
- RLS policies not documented in migrations
- Should have policies allowing users to CRUD their own mileage records

---

### `tax_estimates`
Tax estimate calculations (optional table).

**Columns:**
- (Structure inferred from code usage)
- Referenced in: `lib/delete_account_button.dart`
- Purpose unclear - may be cached calculations or historical estimates

**Notes:**
- RLS policies not documented
- May be optional or deprecated

---

## RLS Policy Patterns

### Standard User Data Pattern
For tables containing user-specific data (`income`, `expenses`, `mileage`), policies should follow this pattern:

```sql
-- Users can insert their own records
CREATE POLICY "Users can insert their own records" ON table_name
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can select their own records
CREATE POLICY "Users can select their own records" ON table_name
    FOR SELECT USING (user_id = auth.uid());

-- Users can update their own records
CREATE POLICY "Users can update their own records" ON table_name
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Users can delete their own records
CREATE POLICY "Users can delete their own records" ON table_name
    FOR DELETE USING (user_id = auth.uid());
```

### Service Role Access
Service role typically has full access for administrative operations:
- Can INSERT/SELECT/UPDATE/DELETE all records
- Used for system operations, migrations, and admin tasks

---

## Migration Files

1. **20250121000000_fix_rls_policies.sql**
   - Fixes RLS policies for `users` table (splits ALL policy into separate INSERT/SELECT/UPDATE)

---

## Common Issues & Solutions

### Issue: "new row violates row-level security policy"
**Cause:** RLS policy doesn't allow the operation
**Solution:** 
- Verify `auth.uid()` matches the `user_id` being inserted/updated
- Check that RLS is enabled and policies exist
- Ensure user is authenticated before database operations

### Issue: User document creation fails during signup
**Cause:** INSERT policy requires `id = auth.uid()` but timing may be off
**Solution:** Policy allows users to insert their own row with matching ID

---

## Notes

- All tables should have RLS enabled for security
- User-specific tables should reference `users(id)` via foreign key
- Timestamps use `TIMESTAMPTZ` for timezone-aware dates
- UUIDs are used for primary keys matching Supabase Auth user IDs
- JSONB columns are used for flexible structured data (device_info, context, tags)
