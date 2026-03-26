-- Add email column to supervisors table if it doesn't exist
ALTER TABLE public.supervisors 
ADD COLUMN IF NOT EXISTS email TEXT;

-- Drop the existing trigger
DROP TRIGGER IF EXISTS on_auth_user_confirmed ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the function to handle supervisor creation properly
CREATE OR REPLACE FUNCTION public.handle_supervisor_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle both INSERT (invitation) and UPDATE (email confirmation) cases
  -- For invitations, create supervisor entry immediately
  IF TG_OP = 'INSERT' AND NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
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
      'pending'
    )
    ON CONFLICT (uid) DO NOTHING;
  END IF;
  
  -- For email confirmation, update status to active
  IF TG_OP = 'UPDATE' 
     AND NEW.email_confirmed_at IS NOT NULL 
     AND OLD.email_confirmed_at IS NULL 
     AND NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
    
    UPDATE public.supervisors 
    SET status = 'active',
        email = COALESCE(NEW.raw_user_meta_data->>'email', NEW.email)
    WHERE uid = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for both INSERT and UPDATE
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_supervisor_signup();

CREATE OR REPLACE TRIGGER on_auth_user_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_supervisor_signup();