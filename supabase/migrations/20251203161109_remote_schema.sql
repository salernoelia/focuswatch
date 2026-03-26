alter table "public"."test_users" drop constraint "test_users_test_supervisor_user_id_fkey";

alter table "public"."test_users" add constraint "test_users_test_supervisor_user_id_fkey" FOREIGN KEY (test_supervisor_user_id) REFERENCES public.user_profiles(user_id) NOT VALID not valid;

alter table "public"."test_users" validate constraint "test_users_test_supervisor_user_id_fkey";


