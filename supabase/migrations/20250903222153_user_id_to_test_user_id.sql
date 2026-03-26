alter table "public"."experiences" drop constraint "experiences_user_id_fkey";

alter table "public"."journals" drop constraint "journals_user_id_fkey";

drop index if exists "public"."ix_experiences_user_id";

drop index if exists "public"."ix_journals_user_id";

alter table "public"."experiences" drop column "user_id";

alter table "public"."experiences" add column "test_user_id" integer not null;

alter table "public"."journals" drop column "user_id";

alter table "public"."journals" add column "test_user_id" integer not null;

CREATE INDEX ix_experiences_user_id ON public.experiences USING btree (test_user_id);

CREATE INDEX ix_journals_user_id ON public.journals USING btree (test_user_id);

alter table "public"."experiences" add constraint "experiences_test_user_id_fkey" FOREIGN KEY (test_user_id) REFERENCES test_users(id) not valid;

alter table "public"."experiences" validate constraint "experiences_test_user_id_fkey";

alter table "public"."journals" add constraint "journals_test_user_id_fkey" FOREIGN KEY (test_user_id) REFERENCES test_users(id) not valid;

alter table "public"."journals" validate constraint "journals_test_user_id_fkey";


