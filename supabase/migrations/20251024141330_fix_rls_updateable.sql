create policy "Authenticated can Update"
on "public"."feedback"
as permissive
for update
to authenticated
using (true)
with check (true);



