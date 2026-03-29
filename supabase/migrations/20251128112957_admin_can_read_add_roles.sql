-- Add new permission value to enum if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        WHERE t.typname = 'app_permission' AND e.enumlabel = 'user_roles.select'
    ) THEN
        ALTER TYPE public.app_permission ADD VALUE 'user_roles.select';
    END IF;
END $$;

COMMIT;

-- Assign permission to admin role
INSERT INTO public.role_permissions (role, permission)
VALUES
    ('admin', 'user_roles.select')
ON CONFLICT (role, permission) DO NOTHING;

-- Grant SELECT on user_roles to authenticated (was revoked in earlier migration)
GRANT SELECT ON TABLE "public"."user_roles" TO authenticated;

-- Drop existing policy if exists and create new one for admins to select user_roles
DROP POLICY IF EXISTS "Users can read own role" ON "public"."user_roles";
DROP POLICY IF EXISTS "Admins can select user_roles" ON "public"."user_roles";

CREATE POLICY "Admins can select user_roles"
ON "public"."user_roles"
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    (SELECT public.authorize('user_roles.select'::public.app_permission))
    OR (auth.uid() = user_id)
);

