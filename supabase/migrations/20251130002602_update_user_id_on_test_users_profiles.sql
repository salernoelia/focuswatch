alter table "public"."test_users" drop constraint "test_users_supervisor_uid_fkey";


  create table "public"."test_user_profiles" (
    "user_id" uuid not null,
    "first_name" text not null,
    "last_name" text not null,
    "occupation_affiliation" text,
    "how_they_found_out" text,
    "beta_agreement_accepted" boolean not null default false,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."test_user_profiles" enable row level security;

alter table "public"."test_users" drop column "supervisor_uid";

alter table "public"."test_users" add column "user_id" uuid;

-- For existing rows, we can't populate user_id without additional context
-- So we'll leave it nullable for now and handle it in a later migration if needed
-- If you need it to be NOT NULL, you'll need to populate existing rows first

CREATE UNIQUE INDEX profiles_pkey ON public.test_user_profiles USING btree (user_id);

alter table "public"."test_user_profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."test_user_profiles" add constraint "profiles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."test_user_profiles" validate constraint "profiles_user_id_fkey";

alter table "public"."test_users" add constraint "test_users_profile_id_fkey" FOREIGN KEY (user_id) REFERENCES public.test_user_profiles(user_id) not valid;

-- Only validate if there are no NULL values, otherwise skip validation for now
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.test_users WHERE user_id IS NULL) THEN
    ALTER TABLE "public"."test_users" validate constraint "test_users_profile_id_fkey";
  END IF;
END $$;

alter table "public"."test_users" add constraint "test_users_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

-- Only validate if there are no NULL values, otherwise skip validation for now
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.test_users WHERE user_id IS NULL) THEN
    ALTER TABLE "public"."test_users" validate constraint "test_users_user_id_fkey";
  END IF;
END $$;

grant delete on table "public"."test_user_profiles" to "anon";

grant insert on table "public"."test_user_profiles" to "anon";

grant references on table "public"."test_user_profiles" to "anon";

grant select on table "public"."test_user_profiles" to "anon";

grant trigger on table "public"."test_user_profiles" to "anon";

grant truncate on table "public"."test_user_profiles" to "anon";

grant update on table "public"."test_user_profiles" to "anon";

grant delete on table "public"."test_user_profiles" to "authenticated";

grant insert on table "public"."test_user_profiles" to "authenticated";

grant references on table "public"."test_user_profiles" to "authenticated";

grant select on table "public"."test_user_profiles" to "authenticated";

grant trigger on table "public"."test_user_profiles" to "authenticated";

grant truncate on table "public"."test_user_profiles" to "authenticated";

grant update on table "public"."test_user_profiles" to "authenticated";

grant delete on table "public"."test_user_profiles" to "postgres";

grant insert on table "public"."test_user_profiles" to "postgres";

grant references on table "public"."test_user_profiles" to "postgres";

grant select on table "public"."test_user_profiles" to "postgres";

grant trigger on table "public"."test_user_profiles" to "postgres";

grant truncate on table "public"."test_user_profiles" to "postgres";

grant update on table "public"."test_user_profiles" to "postgres";

grant delete on table "public"."test_user_profiles" to "service_role";

grant insert on table "public"."test_user_profiles" to "service_role";

grant references on table "public"."test_user_profiles" to "service_role";

grant select on table "public"."test_user_profiles" to "service_role";

grant trigger on table "public"."test_user_profiles" to "service_role";

grant truncate on table "public"."test_user_profiles" to "service_role";

grant update on table "public"."test_user_profiles" to "service_role";


  create policy "Anon can insert profile during signup"
  on "public"."test_user_profiles"
  as permissive
  for insert
  to anon
with check (true);



  create policy "Authenticated users can insert their own profile"
  on "public"."test_user_profiles"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = user_id));



  create policy "Users can read their own profile"
  on "public"."test_user_profiles"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  create policy "Users can update their own profile"
  on "public"."test_user_profiles"
  as permissive
  for update
  to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



