-- Create storage bucket for writing session binary files
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'writing-binaries',
    'writing-binaries',
    false, -- Private bucket
    5242880, -- 5MB limit (sufficient for ~600KB files with headroom)
    ARRAY['application/octet-stream']
)
ON CONFLICT (id) DO NOTHING;

-- Allow anonymous to upload files
CREATE POLICY "anon_can_upload_writing_binaries" ON storage.objects
    FOR INSERT TO anon
    WITH CHECK (
        bucket_id = 'writing-binaries'
    );

-- Allow anonymous to read files
CREATE POLICY "anon_can_read_writing_binaries" ON storage.objects
    FOR SELECT TO anon
    USING (
        bucket_id = 'writing-binaries'
    );

-- Allow authenticated users to read files
CREATE POLICY "authenticated_can_read_writing_binaries" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'writing-binaries'
    );

