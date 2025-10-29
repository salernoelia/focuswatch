drop policy "all auth users can do all crud operations" on "public"."journals";

alter table "public"."experiences" drop constraint "experiences_supervisor_id_fkey";

alter table "public"."journals" drop constraint "journals_supervisor_id_fkey";

alter table "public"."supervisors" drop constraint "supervisors_user_id_fkey";

alter table "public"."test_users" drop constraint "test_users_supervisor_id_fkey";

alter table "public"."supervisors" drop constraint "supervisors_pkey";

drop index if exists "public"."ix_experiences_supervisor_id";

drop index if exists "public"."ix_journals_supervisor_id";

drop index if exists "public"."ix_test_users_supervisor_id";

drop index if exists "public"."supervisors_pkey";

alter table "public"."experiences" drop column "supervisor_id";

alter table "public"."experiences" add column "supervisor_uid" uuid;

alter table "public"."journals" drop column "supervisor_id";

alter table "public"."journals" add column "supervisor_uid" uuid;

alter table "public"."supervisors" drop column "id";

alter table "public"."supervisors" drop column "user_id";

alter table "public"."supervisors" add column "uid" uuid not null;

alter table "public"."test_users" drop column "supervisor_id";

alter table "public"."test_users" add column "supervisor_uid" uuid;

drop sequence if exists "public"."supervisors_id_seq";

CREATE UNIQUE INDEX supervisors_pkey ON public.supervisors USING btree (uid);

alter table "public"."supervisors" add constraint "supervisors_pkey" PRIMARY KEY using index "supervisors_pkey";

alter table "public"."experiences" add constraint "experiences_supervisor_uid_fkey" FOREIGN KEY (supervisor_uid) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."experiences" validate constraint "experiences_supervisor_uid_fkey";

alter table "public"."journals" add constraint "journals_supervisor_uid_fkey" FOREIGN KEY (supervisor_uid) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."journals" validate constraint "journals_supervisor_uid_fkey";

alter table "public"."supervisors" add constraint "supervisors_uid_fkey" FOREIGN KEY (uid) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."supervisors" validate constraint "supervisors_uid_fkey";

alter table "public"."test_users" add constraint "test_users_supervisor_uid_fkey" FOREIGN KEY (supervisor_uid) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."test_users" validate constraint "test_users_supervisor_uid_fkey";

create policy "all auth users can do all crud operations on their own journals"
on "public"."journals"
as permissive
for all
to authenticated
using ((supervisor_uid = auth.uid()))
with check ((supervisor_uid = auth.uid()));



