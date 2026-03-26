drop policy if exists "Admins can read app_logs" on "public"."app_logs";

drop policy if exists "Admins can read all user_roles" on "public"."user_roles";

drop policy if exists "Admins can read all watches" on "public"."watches";

drop policy if exists "Admins can delete test processes" on "public"."test_processes";

drop policy if exists "Testers can insert their own test processes" on "public"."test_processes";

drop policy if exists "Testers can select their own test processes" on "public"."test_processes";

drop policy if exists "Testers can update their own test processes" on "public"."test_processes";

alter type "public"."app_permission" rename to "app_permission__old_version_to_be_dropped";

create type "public"."app_permission" as enum (
  'test_results.select',
  'logs.select',
  'logs.insert',
  'user_roles.select',
  'test_processes.select',
  'test_processes.insert',
  'test_processes.update',
  'test_processes.delete',
  'app_logs.select',
  'apps.select',
  'feedback.select',
  'feedback.update',
  'feedback.delete',
  'journals.select',
  'test_users.select',
  'test_users.insert',
  'test_users.update',
  'test_users.delete',
  'watches.select',
  'user_profiles.select',
  'user_profiles.update',
  'user_profiles.delete'
);

alter table "public"."role_permissions" alter column permission type text using permission::text;

alter table "public"."role_permissions" alter column permission type "public"."app_permission" using permission::"public"."app_permission";

drop function if exists public.authorize(public.app_permission__old_version_to_be_dropped);

CREATE OR REPLACE FUNCTION public.authorize(requested_permission public.app_permission)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  bind_permissions int;
  user_role public.app_role;
begin
  select (auth.jwt() ->> 'user_role')::public.app_role into user_role;

  select count(*)
  into bind_permissions
  from public.role_permissions
  where role_permissions.permission = requested_permission
    and role_permissions.role = user_role;

  return bind_permissions > 0;
end;
$function$;

create policy "Admins can delete test processes"
  on "public"."test_processes"
  as permissive
  for delete
  to authenticated
using (( SELECT public.authorize('test_processes.delete'::public.app_permission) AS authorize));

create policy "Testers can insert their own test processes"
  on "public"."test_processes"
  as permissive
  for insert
  to authenticated
with check (((tester_id = auth.uid()) OR ( SELECT public.authorize('test_processes.insert'::public.app_permission) AS authorize)));

create policy "Testers can select their own test processes"
  on "public"."test_processes"
  as permissive
  for select
  to authenticated
using (((tester_id = auth.uid()) OR ( SELECT public.authorize('test_processes.select'::public.app_permission) AS authorize)));

create policy "Testers can update their own test processes"
  on "public"."test_processes"
  as permissive
  for update
  to authenticated
using (((tester_id = auth.uid()) OR ( SELECT public.authorize('test_processes.update'::public.app_permission) AS authorize)))
with check (((tester_id = auth.uid()) OR ( SELECT public.authorize('test_processes.update'::public.app_permission) AS authorize)));

drop type "public"."app_permission__old_version_to_be_dropped";

alter table "public"."user_profiles" add column "apple_id" text;


  create policy "Authorized select on app_logs"
  on "public"."app_logs"
  as permissive
  for select
  to authenticated
using (public.authorize('logs.select'::public.app_permission));



