drop policy "Anon can insert profile during signup" on "public"."test_user_profiles";

drop policy "Authenticated users can insert their own profile" on "public"."test_user_profiles";

drop policy "Users can read their own profile" on "public"."test_user_profiles";

drop policy "Users can update their own profile" on "public"."test_user_profiles";

revoke delete on table "public"."test_user_profiles" from "anon";

revoke insert on table "public"."test_user_profiles" from "anon";

revoke references on table "public"."test_user_profiles" from "anon";

revoke select on table "public"."test_user_profiles" from "anon";

revoke trigger on table "public"."test_user_profiles" from "anon";

revoke truncate on table "public"."test_user_profiles" from "anon";

revoke update on table "public"."test_user_profiles" from "anon";

revoke delete on table "public"."test_user_profiles" from "authenticated";

revoke insert on table "public"."test_user_profiles" from "authenticated";

revoke references on table "public"."test_user_profiles" from "authenticated";

revoke select on table "public"."test_user_profiles" from "authenticated";

revoke trigger on table "public"."test_user_profiles" from "authenticated";

revoke truncate on table "public"."test_user_profiles" from "authenticated";

revoke update on table "public"."test_user_profiles" from "authenticated";

revoke delete on table "public"."test_user_profiles" from "service_role";

revoke insert on table "public"."test_user_profiles" from "service_role";

revoke references on table "public"."test_user_profiles" from "service_role";

revoke select on table "public"."test_user_profiles" from "service_role";

revoke trigger on table "public"."test_user_profiles" from "service_role";

revoke truncate on table "public"."test_user_profiles" from "service_role";

revoke update on table "public"."test_user_profiles" from "service_role";

alter table "public"."test_user_profiles" drop constraint "profiles_user_id_fkey";

alter table "public"."test_users" drop constraint "test_users_profile_id_fkey";

alter table "public"."test_user_profiles" drop constraint "profiles_pkey";

drop index if exists "public"."profiles_pkey";

drop table "public"."test_user_profiles";


  create table "public"."user_profiles" (
    "user_id" uuid not null,
    "first_name" text not null,
    "last_name" text not null,
    "occupation_affiliation" text,
    "how_they_found_out" text,
    "beta_agreement_accepted" boolean not null default false,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."user_profiles" enable row level security;

CREATE UNIQUE INDEX profiles_pkey ON public.user_profiles USING btree (user_id);

alter table "public"."user_profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."user_profiles" add constraint "profiles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_profiles" validate constraint "profiles_user_id_fkey";

alter table "public"."test_users" add constraint "test_users_profile_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) not valid;

alter table "public"."test_users" validate constraint "test_users_profile_id_fkey";

grant delete on table "public"."user_profiles" to "anon";

grant insert on table "public"."user_profiles" to "anon";

grant references on table "public"."user_profiles" to "anon";

grant select on table "public"."user_profiles" to "anon";

grant trigger on table "public"."user_profiles" to "anon";

grant truncate on table "public"."user_profiles" to "anon";

grant update on table "public"."user_profiles" to "anon";

grant delete on table "public"."user_profiles" to "authenticated";

grant insert on table "public"."user_profiles" to "authenticated";

grant references on table "public"."user_profiles" to "authenticated";

grant select on table "public"."user_profiles" to "authenticated";

grant trigger on table "public"."user_profiles" to "authenticated";

grant truncate on table "public"."user_profiles" to "authenticated";

grant update on table "public"."user_profiles" to "authenticated";

grant delete on table "public"."user_profiles" to "postgres";

grant insert on table "public"."user_profiles" to "postgres";

grant references on table "public"."user_profiles" to "postgres";

grant select on table "public"."user_profiles" to "postgres";

grant trigger on table "public"."user_profiles" to "postgres";

grant truncate on table "public"."user_profiles" to "postgres";

grant update on table "public"."user_profiles" to "postgres";

grant delete on table "public"."user_profiles" to "service_role";

grant insert on table "public"."user_profiles" to "service_role";

grant references on table "public"."user_profiles" to "service_role";

grant select on table "public"."user_profiles" to "service_role";

grant trigger on table "public"."user_profiles" to "service_role";

grant truncate on table "public"."user_profiles" to "service_role";

grant update on table "public"."user_profiles" to "service_role";


  create policy "Anon can insert profile during signup"
  on "public"."user_profiles"
  as permissive
  for insert
  to anon
with check (true);



  create policy "Authenticated users can insert their own profile"
  on "public"."user_profiles"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = user_id));



  create policy "Users can read their own profile"
  on "public"."user_profiles"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  create policy "Users can update their own profile"
  on "public"."user_profiles"
  as permissive
  for update
  to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



