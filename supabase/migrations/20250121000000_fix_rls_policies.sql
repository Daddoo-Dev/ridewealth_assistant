-- Fix RLS policies for users and error_tracking tables

-- Drop existing users policy and recreate with proper INSERT support
DROP POLICY IF EXISTS "Users can access their own row" ON users;

-- Create separate policies for better control
-- Allow users to insert their own user document (during signup)
CREATE POLICY "Users can insert their own row" ON users
    FOR INSERT 
    WITH CHECK (id = auth.uid());

-- Allow users to select their own row
CREATE POLICY "Users can select their own row" ON users
    FOR SELECT 
    USING (id = auth.uid());

-- Allow users to update their own row
CREATE POLICY "Users can update their own row" ON users
    FOR UPDATE 
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Fix error_tracking policy to allow inserts with NULL user_id or matching user_id
DROP POLICY IF EXISTS "Users can insert their own errors" ON error_tracking;

-- Allow authenticated users to insert errors where user_id matches their auth.uid() OR user_id is NULL
CREATE POLICY "Users can insert their own errors" ON error_tracking
    FOR INSERT 
    WITH CHECK (
        (auth.uid() = user_id) OR 
        (user_id IS NULL)
    );

-- Ensure service role can still insert any error (if it doesn't exist, create it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'error_tracking' 
        AND policyname = 'Service role can insert any error'
    ) THEN
        CREATE POLICY "Service role can insert any error" ON error_tracking
            FOR INSERT 
            WITH CHECK (auth.role() = 'service_role');
    END IF;
END $$;
