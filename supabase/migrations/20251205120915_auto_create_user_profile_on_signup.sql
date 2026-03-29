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

DROP TRIGGER IF EXISTS on_auth_user_created_tester_profile ON auth.users;

CREATE TRIGGER on_auth_user_created_tester_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_tester_signup();

