drop policy "authenticated users can insert app_logs" on "public"."app_logs";

alter table "public"."app_logs" add column "watch_id" uuid not null;


  create policy "users can insert app_logs"
  on "public"."app_logs"
  as permissive
  for insert
  to anon
with check (true);



