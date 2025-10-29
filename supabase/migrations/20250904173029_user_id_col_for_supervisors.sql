alter table "public"."test_users" drop constraint "test_users_supervisor_id_fkey";

alter table "public"."supervisors" add column "user_id" uuid;

alter table "public"."test_users" alter column "supervisor_id" drop not null;

alter table "public"."supervisors" add constraint "supervisors_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."supervisors" validate constraint "supervisors_user_id_fkey";

alter table "public"."test_users" add constraint "test_users_supervisor_id_fkey" FOREIGN KEY (supervisor_id) REFERENCES supervisors(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."test_users" validate constraint "test_users_supervisor_id_fkey";


