create extension if not exists "pg_net" with schema "extensions";

drop policy "all users can insert app_logs" on "public"."app_logs";

alter table "public"."app_logs" drop constraint "app_logs_app_id_fkey";


  create policy "users can insert app_logs"
  on "public"."app_logs"
  as permissive
  for insert
  to anon
with check (true);



