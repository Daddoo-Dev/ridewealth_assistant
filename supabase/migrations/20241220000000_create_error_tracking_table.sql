-- Create error_tracking table for custom error logging system
CREATE TABLE IF NOT EXISTS error_tracking (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    error_type TEXT NOT NULL CHECK (error_type IN ('authentication', 'database', 'ui', 'general')),
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    platform TEXT,
    app_version TEXT,
    device_info JSONB,
    context JSONB,
    tags JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    resolution_notes TEXT
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_error_tracking_error_type ON error_tracking(error_type);
CREATE INDEX IF NOT EXISTS idx_error_tracking_user_id ON error_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_error_tracking_created_at ON error_tracking(created_at);
CREATE INDEX IF NOT EXISTS idx_error_tracking_resolved_at ON error_tracking(resolved_at);

-- Create a function to automatically set app_version from device_info
CREATE OR REPLACE FUNCTION set_app_version()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.device_info IS NOT NULL AND NEW.device_info ? 'app_version' THEN
        NEW.app_version := NEW.device_info->>'app_version';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set app_version
CREATE TRIGGER trigger_set_app_version
    BEFORE INSERT ON error_tracking
    FOR EACH ROW
    EXECUTE FUNCTION set_app_version();

-- Enable Row Level Security
ALTER TABLE error_tracking ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users to insert their own errors
CREATE POLICY "Users can insert their own errors" ON error_tracking
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR user_id IS NULL
    );

-- Create policy for service role to insert any error (for system errors)
CREATE POLICY "Service role can insert any error" ON error_tracking
    FOR INSERT WITH CHECK (
        auth.role() = 'service_role'
    );

-- Create policy for authenticated users to view their own errors
CREATE POLICY "Users can view their own errors" ON error_tracking
    FOR SELECT USING (
        auth.uid() = user_id OR user_id IS NULL
    );

-- Create policy for service role to view all errors
CREATE POLICY "Service role can view all errors" ON error_tracking
    FOR SELECT USING (
        auth.role() = 'service_role'
    );

-- Create policy for service role to update errors (for resolution)
CREATE POLICY "Service role can update errors" ON error_tracking
    FOR UPDATE USING (
        auth.role() = 'service_role'
    );

-- Create a view for error analytics (only accessible by service role)
CREATE VIEW error_analytics AS
SELECT 
    error_type,
    platform,
    app_version,
    DATE(created_at) as error_date,
    COUNT(*) as error_count,
    COUNT(DISTINCT user_id) as affected_users,
    COUNT(CASE WHEN resolved_at IS NOT NULL THEN 1 END) as resolved_count
FROM error_tracking
GROUP BY error_type, platform, app_version, DATE(created_at);

-- Grant access to the analytics view
GRANT SELECT ON error_analytics TO service_role;
