-- Fix the trigger to ONLY create profiles for supervisor invites, NOT for tester signups
-- Testers will use ProfileCreationDialog to complete their profile after email verification

CREATE OR REPLACE FUNCTION public.handle_tester_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only create profile for SUPERVISOR invites (they have role='supervisor' in metadata)
  -- Regular testers should use ProfileCreationDialog after login
  IF NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = NEW.id) THEN
      INSERT INTO public.user_profiles (
        user_id,
        first_name,
        last_name,
        email,
        status,
        beta_agreement_accepted,
        created_at,
        updated_at
      ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NEW.email,
        'active',
        false,
        NOW(),
        NOW()
      )
      ON CONFLICT (user_id) DO UPDATE
      SET 
        email = EXCLUDED.email,
        status = EXCLUDED.status,
        updated_at = NOW();
      
      -- Assign default 'user' role for supervisors
      INSERT INTO public.user_roles (user_id, role)
      VALUES (NEW.id, 'user'::public.app_role)
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;



