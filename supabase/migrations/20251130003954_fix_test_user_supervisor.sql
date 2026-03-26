create sequence "public"."test_processes_id_seq";

alter table "public"."test_users" drop constraint "test_users_profile_id_fkey";

alter table "public"."test_users" drop constraint "test_users_user_id_fkey";

alter type "public"."app_permission" rename to "app_permission__old_version_to_be_dropped";

create type "public"."app_permission" as enum ('test_results.select', 'logs.select', 'logs.insert', 'user_roles.select', 'test_processes.select', 'test_processes.insert', 'test_processes.update', 'test_processes.delete');

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


  create table "public"."test_processes" (
    "id" bigint not null default nextval('public.test_processes_id_seq'::regclass),
    "test_user_id" integer not null,
    "tester_id" uuid not null,
    "start_date" date not null,
    "end_date" date,
    "status" text not null default 'setup'::text,
    "initial_questions" jsonb,
    "mid_term_questions" jsonb,
    "exit_interview" jsonb,
    "daily_logs" jsonb default '[]'::jsonb,
    "locked_forms" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."test_processes" enable row level security;

-- Fix role_permissions.permission column type after enum rename
-- Convert through text to break the dependency on the old enum type
alter table "public"."role_permissions" alter column permission type text using permission::text;
alter table "public"."role_permissions" alter column permission type "public"."app_permission" using permission::"public"."app_permission";


alter table "public"."test_users" drop column "user_id";

alter table "public"."test_users" add column "test_supervisor_user_id" uuid;

-- For existing rows, we can't populate test_supervisor_user_id without additional context
-- So we'll leave it nullable for now and handle it in a later migration if needed
-- If you need it to be NOT NULL, you'll need to populate existing rows first

alter sequence "public"."test_processes_id_seq" owned by "public"."test_processes"."id";

CREATE INDEX idx_test_processes_start_date ON public.test_processes USING btree (start_date);

CREATE INDEX idx_test_processes_status ON public.test_processes USING btree (status);

CREATE INDEX idx_test_processes_test_user_id ON public.test_processes USING btree (test_user_id);

CREATE INDEX idx_test_processes_tester_id ON public.test_processes USING btree (tester_id);

CREATE UNIQUE INDEX test_processes_pkey ON public.test_processes USING btree (id);

alter table "public"."test_processes" add constraint "test_processes_pkey" PRIMARY KEY using index "test_processes_pkey";

alter table "public"."test_processes" add constraint "test_processes_status_check" CHECK ((status = ANY (ARRAY['setup'::text, 'active'::text, 'mid_check'::text, 'completed'::text, 'cancelled'::text]))) not valid;

alter table "public"."test_processes" validate constraint "test_processes_status_check";

alter table "public"."test_processes" add constraint "test_processes_test_user_id_fkey" FOREIGN KEY (test_user_id) REFERENCES public.test_users(id) ON DELETE CASCADE not valid;

alter table "public"."test_processes" validate constraint "test_processes_test_user_id_fkey";

alter table "public"."test_processes" add constraint "test_processes_tester_id_fkey" FOREIGN KEY (tester_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."test_processes" validate constraint "test_processes_tester_id_fkey";

alter table "public"."test_users" add constraint "test_users_test_supervisor_user_id_fkey" FOREIGN KEY (test_supervisor_user_id) REFERENCES public.user_profiles(user_id) not valid;

-- Only validate if there are no NULL values, otherwise skip validation for now
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.test_users WHERE test_supervisor_user_id IS NULL) THEN
    ALTER TABLE "public"."test_users" validate constraint "test_users_test_supervisor_user_id_fkey";
  END IF;
END $$;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_test_processes_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

grant delete on table "public"."test_processes" to "anon";

grant insert on table "public"."test_processes" to "anon";

grant references on table "public"."test_processes" to "anon";

grant select on table "public"."test_processes" to "anon";

grant trigger on table "public"."test_processes" to "anon";

grant truncate on table "public"."test_processes" to "anon";

grant update on table "public"."test_processes" to "anon";

grant delete on table "public"."test_processes" to "authenticated";

grant insert on table "public"."test_processes" to "authenticated";

grant references on table "public"."test_processes" to "authenticated";

grant select on table "public"."test_processes" to "authenticated";

grant trigger on table "public"."test_processes" to "authenticated";

grant truncate on table "public"."test_processes" to "authenticated";

grant update on table "public"."test_processes" to "authenticated";

grant delete on table "public"."test_processes" to "postgres";

grant insert on table "public"."test_processes" to "postgres";

grant references on table "public"."test_processes" to "postgres";

grant select on table "public"."test_processes" to "postgres";

grant trigger on table "public"."test_processes" to "postgres";

grant truncate on table "public"."test_processes" to "postgres";

grant update on table "public"."test_processes" to "postgres";

grant delete on table "public"."test_processes" to "service_role";

grant insert on table "public"."test_processes" to "service_role";

grant references on table "public"."test_processes" to "service_role";

grant select on table "public"."test_processes" to "service_role";

grant trigger on table "public"."test_processes" to "service_role";

grant truncate on table "public"."test_processes" to "service_role";

grant update on table "public"."test_processes" to "service_role";

grant delete on table "public"."user_profiles" to "postgres";

grant insert on table "public"."user_profiles" to "postgres";

grant references on table "public"."user_profiles" to "postgres";

grant select on table "public"."user_profiles" to "postgres";

grant trigger on table "public"."user_profiles" to "postgres";

grant truncate on table "public"."user_profiles" to "postgres";

grant update on table "public"."user_profiles" to "postgres";


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


CREATE TRIGGER test_processes_updated_at BEFORE UPDATE ON public.test_processes FOR EACH ROW EXECUTE FUNCTION public.update_test_processes_updated_at();


