-- Comprehensive admin permissions fix
-- This migration ensures admins have full read access to all tables needed for the admin dashboard

-- ============================================================================
-- STEP 1: Add missing permission values to the app_permission enum
-- ============================================================================

DO $$
BEGIN
  -- app_logs permissions
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'app_logs.select'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'app_logs.select';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  -- apps permissions
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'apps.select'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'apps.select';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  -- feedback permissions
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'feedback.select'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'feedback.select';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'feedback.update'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'feedback.update';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'feedback.delete'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'feedback.delete';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  -- journals permissions
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'journals.select'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'journals.select';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  -- test_users permissions
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'test_users.select'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'test_users.select';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'test_users.insert'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'test_users.insert';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'test_users.update'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'test_users.update';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'test_users.delete'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'test_users.delete';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  -- watches permissions
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'watches.select'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'watches.select';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  -- user_profiles permissions
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'user_profiles.select'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'user_profiles.select';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'user_profiles.update'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'user_profiles.update';
  END IF;
END $$;
COMMIT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'app_permission' AND e.enumlabel = 'user_profiles.delete'
  ) THEN
    ALTER TYPE public.app_permission ADD VALUE 'user_profiles.delete';
  END IF;
END $$;
COMMIT;

-- ============================================================================
-- STEP 2: Grant admin all necessary permissions
-- ============================================================================

INSERT INTO public.role_permissions (role, permission)
VALUES
    -- app_logs
    ('admin', 'app_logs.select'),
    -- apps
    ('admin', 'apps.select'),
    -- feedback
    ('admin', 'feedback.select'),
    ('admin', 'feedback.update'),
    ('admin', 'feedback.delete'),
    -- journals
    ('admin', 'journals.select'),
    -- test_users
    ('admin', 'test_users.select'),
    ('admin', 'test_users.insert'),
    ('admin', 'test_users.update'),
    ('admin', 'test_users.delete'),
    -- watches
    ('admin', 'watches.select'),
    -- user_profiles
    ('admin', 'user_profiles.select'),
    ('admin', 'user_profiles.update'),
    ('admin', 'user_profiles.delete')
ON CONFLICT (role, permission) DO NOTHING;

-- ============================================================================
-- STEP 3: Fix app_logs RLS policy (currently broken - no SELECT policy for admin)
-- ============================================================================

-- Drop the old broken policy if it exists
DROP POLICY IF EXISTS "Admins can read app_logs" ON public.app_logs;

-- Create new policy using authorize function
CREATE POLICY "Admins can read app_logs"
ON public.app_logs
FOR SELECT
TO authenticated
USING (public.authorize('app_logs.select'::public.app_permission));

-- ============================================================================
-- STEP 4: Add admin SELECT policy to watches table
-- ============================================================================

DROP POLICY IF EXISTS "Admins can read all watches" ON public.watches;

CREATE POLICY "Admins can read all watches"
ON public.watches
FOR SELECT
TO authenticated
USING (public.authorize('watches.select'::public.app_permission));

-- ============================================================================
-- STEP 5: Add admin SELECT policy to user_roles table
-- ============================================================================

DROP POLICY IF EXISTS "Admins can read all user_roles" ON public.user_roles;

CREATE POLICY "Admins can read all user_roles"
ON public.user_roles
FOR SELECT
TO authenticated
USING (public.authorize('user_roles.select'::public.app_permission));
