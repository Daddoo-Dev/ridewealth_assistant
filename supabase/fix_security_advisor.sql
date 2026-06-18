BEGIN;

DROP TABLE IF EXISTS public.processed_stripe_events CASCADE;

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('approval_tokens', 'organizations', 'users')
      AND (
        regexp_replace(lower(trim(coalesce(qual, ''))), '\s+', '', 'g') IN ('true', '(true)')
        OR regexp_replace(lower(trim(coalesce(with_check, ''))), '\s+', '', 'g') IN ('true', '(true)')
      )
  LOOP
    RAISE NOTICE 'Dropping permissive policy % on %.%', r.policyname, r.schemaname, r.tablename;
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      r.policyname, r.schemaname, r.tablename
    );
  END LOOP;
END $$;

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS proc
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef
      AND p.proname IN ('handle_new_user', 'update_my_profile', 'app_usage_weekly_digest')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', r.proc);
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM anon', r.proc);
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM authenticated', r.proc);
  END LOOP;
END $$;

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS proc
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'handle_new_user'
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO supabase_auth_admin', r.proc);
  END LOOP;
END $$;

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS proc
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef
      AND p.proname IN ('handle_new_user', 'update_my_profile', 'app_usage_weekly_digest')
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', r.proc);
  END LOOP;
END $$;

COMMIT;
