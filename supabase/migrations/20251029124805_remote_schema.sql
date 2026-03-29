drop extension if exists "pg_net";

drop policy "users can insert app_logs" on "public"."app_logs";


  create policy "all users can insert app_logs"
  on "public"."app_logs"
  as permissive
  for insert
  to anon
with check (true);



