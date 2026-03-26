-- Fix role_permissions.permission column type after enum rename
-- The column still references the old enum type internally after rename
-- This migration fixes the type mismatch by converting through text

DO $$
BEGIN
  -- Check if the old enum type exists (it was renamed in the previous migration)
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_permission__old_version_to_be_dropped') THEN
    -- Convert column to text first to break type dependency on old enum
    ALTER TABLE public.role_permissions 
      ALTER COLUMN permission TYPE text USING permission::text;
    
    -- Convert back to the new enum type
    ALTER TABLE public.role_permissions 
      ALTER COLUMN permission TYPE public.app_permission USING permission::public.app_permission;
    
    -- Now safe to drop the old enum type
    DROP TYPE IF EXISTS public.app_permission__old_version_to_be_dropped CASCADE;
  END IF;
END $$;

