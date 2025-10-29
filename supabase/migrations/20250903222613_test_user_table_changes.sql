create type "public"."genders" as enum ('male', 'female', 'hidden');

alter table "public"."supervisors" alter column "last_name" set not null;

alter table "public"."test_users" add column "gender" genders not null default 'male'::genders;

alter table "public"."test_users" alter column "last_name" set not null;


