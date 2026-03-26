-- Allow testers to delete their own test processes
-- This updates the existing delete policy to allow testers to delete test processes where they are the owner (tester_id = auth.uid())
-- Admins can still delete any test process via the test_processes.delete permission

-- Drop the existing policy
DROP POLICY IF EXISTS "Admins can delete test processes" ON public.test_processes;

-- Create new policy that allows both testers (their own) and admins (any)
CREATE POLICY "Testers can delete their own test processes"
ON public.test_processes
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  (tester_id = auth.uid()) OR 
  (authorize('test_processes.delete'::app_permission))
);

