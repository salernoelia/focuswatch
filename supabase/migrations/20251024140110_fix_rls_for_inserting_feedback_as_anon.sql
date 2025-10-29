drop policy "Disable insert for everyone" on "public"."feedback";

create policy "Enable Insert for anyone"
on "public"."feedback"
as permissive
for insert
to anon, authenticated
with check (true);



