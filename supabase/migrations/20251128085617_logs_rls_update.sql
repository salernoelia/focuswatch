drop policy "authenticated users can read app_logs" on "public"."app_logs";

drop policy "users can insert app_logs" on "public"."app_logs";

set check_function_bodies = off;

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
  -- Fetch user role once and store it to reduce number of calls
  select (auth.jwt() ->> 'user_role')::public.app_role into user_role;

  select count(*)
  into bind_permissions
  from public.role_permissions
  where role_permissions.permission = requested_permission
    and role_permissions.role = user_role;

  return bind_permissions > 0;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
  declare
    claims jsonb;
    user_role public.app_role;
  begin
    -- Fetch the user role in the user_roles table
    select role into user_role from public.user_roles where user_id = (event->>'user_id')::uuid;

    claims := event->'claims';

    if user_role is not null then
      -- Set the claim
      claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
    else
      claims := jsonb_set(claims, '{user_role}', 'null');
    end if;

    -- Update the 'claims' object in the original event
    event := jsonb_set(event, '{claims}', claims);

    -- Return the modified or original event
    return event;
  end;
$function$
;


  create policy "Admins can read app_logs"
  on "public"."app_logs"
  as permissive
  for select
  to authenticated
using (( SELECT public.authorize('logs.select'::public.app_permission) AS authorize));



  create policy "Users can insert app_logs"
  on "public"."app_logs"
  as permissive
  for insert
  to anon
with check (( SELECT public.authorize('logs.insert'::public.app_permission) AS authorize));



