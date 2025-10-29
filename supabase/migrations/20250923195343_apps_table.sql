alter table "public"."apps" drop column "description";

alter table "public"."apps" add column "data" jsonb;

alter table "public"."journals" add column "app_id" bigint;

alter table "public"."journals" add constraint "journals_app_id_fkey" FOREIGN KEY (app_id) REFERENCES apps(id) not valid;

alter table "public"."journals" validate constraint "journals_app_id_fkey";


