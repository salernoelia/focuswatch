-- Fix 1: Drop the recursive RLS policies on user_roles
DROP POLICY IF EXISTS "Admins can select all user roles" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can insert user roles" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can update user roles" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can delete user roles" ON public.user_roles;

-- Recreate policies using JWT claim instead of querying user_roles table (avoids recursion)
CREATE POLICY "Admins can select all user roles"
ON public.user_roles
FOR SELECT
TO authenticated
USING (
  (auth.jwt() ->> 'user_role')::public.app_role = 'admin'::public.app_role
);

CREATE POLICY "Admins can insert user roles"
ON public.user_roles
FOR INSERT
TO authenticated
WITH CHECK (
  (auth.jwt() ->> 'user_role')::public.app_role = 'admin'::public.app_role
);

CREATE POLICY "Admins can update user roles"
ON public.user_roles
FOR UPDATE
TO authenticated
USING (
  (auth.jwt() ->> 'user_role')::public.app_role = 'admin'::public.app_role
)
WITH CHECK (
  (auth.jwt() ->> 'user_role')::public.app_role = 'admin'::public.app_role
);

CREATE POLICY "Admins can delete user roles"
ON public.user_roles
FOR DELETE
TO authenticated
USING (
  (auth.jwt() ->> 'user_role')::public.app_role = 'admin'::public.app_role
);

-- Fix 2: Update trigger function to use schema-qualified type
CREATE OR REPLACE FUNCTION public.handle_tester_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only create profile if it doesn't exist and if signup metadata is present
  IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = NEW.id) THEN
    -- Check if this is a tester signup (has signup metadata)
    IF NEW.raw_user_meta_data->>'first_name' IS NOT NULL THEN
      INSERT INTO public.user_profiles (
        user_id,
        first_name,
        last_name,
        occupation_affiliation,
        how_they_found_out,
        beta_agreement_accepted,
        email,
        status,
        created_at,
        updated_at
      ) VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name',
        NULLIF(NEW.raw_user_meta_data->>'occupation_affiliation', ''),
        NEW.raw_user_meta_data->>'how_they_found_out',
        COALESCE((NEW.raw_user_meta_data->>'beta_agreement_accepted')::boolean, false),
        NEW.email,
        'active',
        NOW(),
        NOW()
      )
      ON CONFLICT (user_id) DO NOTHING;
      
      -- Assign default 'user' role (use schema-qualified type)
      INSERT INTO public.user_roles (user_id, role)
      VALUES (NEW.id, 'user'::public.app_role)
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;



