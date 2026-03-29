-- Grant INSERT, UPDATE, DELETE on user_roles to authenticated role
-- The RLS policies will control who can actually perform these operations
GRANT INSERT, UPDATE, DELETE ON TABLE public.user_roles TO authenticated;



