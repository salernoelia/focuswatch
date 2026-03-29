drop policy "all auth users can do all crud operations" on "public"."supervisors";

drop policy "Users can read their own profile" on "public"."user_profiles";

revoke delete on table "public"."supervisors" from "anon";

revoke insert on table "public"."supervisors" from "anon";

revoke references on table "public"."supervisors" from "anon";

revoke select on table "public"."supervisors" from "anon";

revoke trigger on table "public"."supervisors" from "anon";

revoke truncate on table "public"."supervisors" from "anon";

revoke update on table "public"."supervisors" from "anon";

revoke delete on table "public"."supervisors" from "authenticated";

revoke insert on table "public"."supervisors" from "authenticated";

revoke references on table "public"."supervisors" from "authenticated";

revoke select on table "public"."supervisors" from "authenticated";

revoke trigger on table "public"."supervisors" from "authenticated";

revoke truncate on table "public"."supervisors" from "authenticated";

revoke update on table "public"."supervisors" from "authenticated";

revoke delete on table "public"."supervisors" from "service_role";

revoke insert on table "public"."supervisors" from "service_role";

revoke references on table "public"."supervisors" from "service_role";

revoke select on table "public"."supervisors" from "service_role";

revoke trigger on table "public"."supervisors" from "service_role";

revoke truncate on table "public"."supervisors" from "service_role";

revoke update on table "public"."supervisors" from "service_role";

alter table "public"."supervisors" drop constraint "supervisors_status_check";

alter table "public"."supervisors" drop constraint "supervisors_uid_fkey";

alter table "public"."supervisors" drop constraint "supervisors_pkey";

drop index if exists "public"."supervisors_pkey";

drop table "public"."supervisors";

alter table "public"."user_profiles" add column "email" text;

alter table "public"."user_profiles" add column "status" text default 'active'::text;

alter table "public"."user_profiles" add constraint "user_profiles_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text]))) not valid;

alter table "public"."user_profiles" validate constraint "user_profiles_status_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_supervisor_signup()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Check if this user was invited as a supervisor
  IF NEW.raw_user_meta_data->>'role' = 'supervisor' THEN
    -- Insert into user_profiles table instead of supervisors
    INSERT INTO public.user_profiles (
      user_id,
      first_name,
      last_name,
      email,
      status,
      beta_agreement_accepted,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      NEW.raw_user_meta_data->>'first_name',
      NEW.raw_user_meta_data->>'last_name',
      NEW.email,
      'active',
      false,
      NOW(),
      NOW()
    )
    ON CONFLICT (user_id) DO UPDATE
    SET 
      email = EXCLUDED.email,
      status = EXCLUDED.status,
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$function$
;


  create policy "Admins can select all profiles"
  on "public"."user_profiles"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_roles ur
  WHERE ((ur.user_id = auth.uid()) AND (ur.role = 'admin'::public.app_role)))));



  create policy "Admins can update any profile"
  on "public"."user_profiles"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_roles ur
  WHERE ((ur.user_id = auth.uid()) AND (ur.role = 'admin'::public.app_role)))))
with check ((EXISTS ( SELECT 1
   FROM public.user_roles ur
  WHERE ((ur.user_id = auth.uid()) AND (ur.role = 'admin'::public.app_role)))));



  create policy "Users can read their own profile"
  on "public"."user_profiles"
  as permissive
  for select
  to authenticated
using (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM public.user_roles ur
  WHERE ((ur.user_id = auth.uid()) AND (ur.role = 'admin'::public.app_role))))));



