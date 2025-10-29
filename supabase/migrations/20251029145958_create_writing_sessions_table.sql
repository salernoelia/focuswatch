-- Create writing_sessions table to store session JSON data
CREATE TABLE IF NOT EXISTS public.writing_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    session_date TEXT NOT NULL,
    session_filename TEXT NOT NULL,
    config JSONB,
    location JSONB,
    app_version TEXT,
    session_end_date TEXT,
    state_history JSONB,
    model_result JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    binary_file_path TEXT -- Path to binary file in storage
);

-- Enable RLS
ALTER TABLE public.writing_sessions ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts (for watch app)
CREATE POLICY "anon_can_insert_writing_sessions" ON public.writing_sessions
    FOR INSERT TO anon
    WITH CHECK (true);

-- Allow authenticated users to read their own sessions
CREATE POLICY "authenticated_can_read_writing_sessions" ON public.writing_sessions
    FOR SELECT TO authenticated
    USING (true);

-- Create index for faster queries
CREATE INDEX idx_writing_sessions_device_id ON public.writing_sessions(device_id);
CREATE INDEX idx_writing_sessions_session_date ON public.writing_sessions(session_date);
CREATE INDEX idx_writing_sessions_created_at ON public.writing_sessions(created_at);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_writing_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_writing_sessions_updated_at
    BEFORE UPDATE ON public.writing_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_writing_sessions_updated_at();

