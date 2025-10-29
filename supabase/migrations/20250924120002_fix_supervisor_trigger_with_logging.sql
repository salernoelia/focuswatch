-- Fix the supervisor creation trigger to handle invitations properly
CREATE OR REPLACE FUNCTION public.handle_supervisor_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Debug logging
  RAISE LOG 'Trigger fired: TG_OP=%, role=%, email_confirmed_at=%, id=%', 
    TG_OP, 
    NEW.raw_user_meta_data->>'role', 
    NEW.email_confirmed_at,
    NEW.id;
  
  -- Handle INSERT (user invitation/creation)
  IF TG_OP = 'INSERT' AND NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
    -- Insert into supervisors table with pending status
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
      CASE 
        WHEN NEW.email_confirmed_at IS NOT NULL THEN 'active'
        ELSE 'pending'
      END
    )
    ON CONFLICT (uid) DO UPDATE SET
      first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      email = EXCLUDED.email,
      status = EXCLUDED.status;
      
    RAISE LOG 'Supervisor created/updated for user %', NEW.id;
  END IF;
  
  -- Handle UPDATE (email confirmation or other updates)
  IF TG_OP = 'UPDATE' 
     AND NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
    
    -- Update supervisor status based on email confirmation
    UPDATE public.supervisors 
    SET status = CASE 
        WHEN NEW.email_confirmed_at IS NOT NULL THEN 'active'
        ELSE 'pending'
      END,
      email = COALESCE(NEW.raw_user_meta_data->>'email', NEW.email),
      first_name = NEW.raw_user_meta_data->>'first_name',
      last_name = NEW.raw_user_meta_data->>'last_name'
    WHERE uid = NEW.id;
    
    RAISE LOG 'Supervisor status updated for user %', NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;