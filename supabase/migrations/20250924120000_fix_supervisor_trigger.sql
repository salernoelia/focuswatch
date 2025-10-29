-- Drop the existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the function to handle email confirmation status
CREATE OR REPLACE FUNCTION public.handle_supervisor_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process when user confirms their email (email_confirmed_at is set)
  -- and they have the supervisor role
  IF NEW.email_confirmed_at IS NOT NULL 
     AND OLD.email_confirmed_at IS NULL 
     AND NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
    
    -- Insert into supervisors table
    INSERT INTO public.supervisors (
      uid,
      first_name,
      last_name,
      email,
      status
    ) VALUES (
      NEW.id,
      NEW.raw_user_meta_data->>'first_name',
      NEW.raw_user_meta_data->>'last_name',
      COALESCE(NEW.raw_user_meta_data->>'email', NEW.email),
      'active'
    )
    ON CONFLICT (uid) DO UPDATE SET
      first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      email = EXCLUDED.email,
      status = 'active';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires when a user record is updated (email confirmation)
CREATE OR REPLACE TRIGGER on_auth_user_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_supervisor_signup();