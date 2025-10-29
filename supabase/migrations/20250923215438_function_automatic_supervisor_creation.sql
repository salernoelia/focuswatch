-- Add status column to supervisors table
ALTER TABLE public.supervisors 
ADD COLUMN status text DEFAULT 'pending' CHECK (status IN ('pending', 'active'));

-- Create function to automatically create supervisor entry when user signs up
CREATE OR REPLACE FUNCTION public.handle_supervisor_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if this user was invited as a supervisor
  IF NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
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
      NEW.email,
      'active'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires when a user signs up (confirms their email)
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_supervisor_signup();