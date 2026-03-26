-- Fix: Update existing user_profiles with empty emails from auth.users
UPDATE public.user_profiles up
SET email = au.email
FROM auth.users au
WHERE up.user_id = au.id
  AND (up.email IS NULL OR up.email = '');



