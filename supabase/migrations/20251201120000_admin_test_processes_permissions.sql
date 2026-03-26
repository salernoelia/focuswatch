-- Grant admin permissions for test_processes operations
-- Admins need full CRUD access to test_processes for management purposes

INSERT INTO public.role_permissions (role, permission)
VALUES
    ('admin', 'test_processes.select'),
    ('admin', 'test_processes.insert'),
    ('admin', 'test_processes.update'),
    ('admin', 'test_processes.delete')
ON CONFLICT (role, permission) DO NOTHING;







