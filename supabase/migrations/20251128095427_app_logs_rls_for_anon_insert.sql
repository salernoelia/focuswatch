drop policy "Users can insert app_logs" on "public"."app_logs";

alter table "public"."role_permissions" enable row level security;

alter table "public"."user_roles" enable row level security;


  create policy "Authenticated users can read role_permissions"
  on "public"."role_permissions"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Users can read own role"
  on "public"."user_roles"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  create policy "Users can insert app_logs"
  on "public"."app_logs"
  as permissive
  for insert
  to anon
with check (true);



