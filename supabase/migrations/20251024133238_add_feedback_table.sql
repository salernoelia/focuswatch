create table "public"."feedback" (
    "id" integer not null default nextval('journals_id_seq'::regclass),
    "description" text,
    "app_name" text,
    "created_at" timestamp with time zone not null default now()
);


alter table "public"."feedback" enable row level security;

alter table "public"."journals" alter column "created_at" drop not null;

CREATE UNIQUE INDEX feedback_pkey ON public.feedback USING btree (id);

alter table "public"."feedback" add constraint "feedback_pkey" PRIMARY KEY using index "feedback_pkey";

grant delete on table "public"."feedback" to "anon";

grant insert on table "public"."feedback" to "anon";

grant references on table "public"."feedback" to "anon";

grant select on table "public"."feedback" to "anon";

grant trigger on table "public"."feedback" to "anon";

grant truncate on table "public"."feedback" to "anon";

grant update on table "public"."feedback" to "anon";

grant delete on table "public"."feedback" to "authenticated";

grant insert on table "public"."feedback" to "authenticated";

grant references on table "public"."feedback" to "authenticated";

grant select on table "public"."feedback" to "authenticated";

grant trigger on table "public"."feedback" to "authenticated";

grant truncate on table "public"."feedback" to "authenticated";

grant update on table "public"."feedback" to "authenticated";

grant delete on table "public"."feedback" to "service_role";

grant insert on table "public"."feedback" to "service_role";

grant references on table "public"."feedback" to "service_role";

grant select on table "public"."feedback" to "service_role";

grant trigger on table "public"."feedback" to "service_role";

grant truncate on table "public"."feedback" to "service_role";

grant update on table "public"."feedback" to "service_role";

create policy "Disable insert for everyone"
on "public"."feedback"
as restrictive
for insert
to authenticated, anon
with check (false);


create policy "Enable delete for authenticated users only"
on "public"."feedback"
as permissive
for delete
to authenticated
using ((auth.uid() IS NOT NULL));


create policy "Enable select for authenticated users only"
on "public"."feedback"
as permissive
for select
to authenticated
using ((auth.uid() IS NOT NULL));



