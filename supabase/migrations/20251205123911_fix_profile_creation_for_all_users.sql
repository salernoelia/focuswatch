-- Fix: Create a basic profile for ALL new users on signup
-- This ensures admins can see all users in user management

CREATE OR REPLACE FUNCTION public.handle_tester_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create profile for ALL new users (if they don't have one yet)
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
      CASE 
        WHEN NEW.raw_user_meta_data->>'role' = 'supervisor' THEN 'active'
        ELSE 'pending'
      END,
      false,
      NOW(),
      NOW()
    )
    ON CONFLICT (user_id) DO UPDATE
    SET 
      email = EXCLUDED.email,
      updated_at = NOW();
    
    -- Assign default 'user' role for all new users
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'user'::public.app_role)
    ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create profiles for existing users who don't have one
INSERT INTO public.user_profiles (user_id, first_name, last_name, email, status, beta_agreement_accepted, created_at, updated_at)
SELECT 
  au.id,
  COALESCE(au.raw_user_meta_data->>'first_name', ''),
  COALESCE(au.raw_user_meta_data->>'last_name', ''),
  au.email,
  'pending',
  false,
  NOW(),
  NOW()
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.user_profiles up WHERE up.user_id = au.id)
ON CONFLICT (user_id) DO NOTHING;

-- Create user_roles entries for existing users who don't have one
INSERT INTO public.user_roles (user_id, role)
SELECT au.id, 'user'::public.app_role
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = au.id)
ON CONFLICT DO NOTHING;



