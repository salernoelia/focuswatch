-- Experiences table
create policy "all auth users can do all crud operations"
  on "public"."experiences"
  as permissive
  for all
  to authenticated
  using (true)
  with check (true);

-- Journals table
create policy "all auth users can do all crud operations"
  on "public"."journals"
  as permissive
  for all
  to authenticated
  using (true)
  with check (true);

-- Supervisors table
create policy "all auth users can do all crud operations"
  on "public"."supervisors"
  as permissive
  for all
  to authenticated
  using (true)
  with check (true);

-- Test Users table
create policy "all auth users can do all crud operations"
  on "public"."test_users"
  as permissive
  for all
  to authenticated
  using (true)
  with check (true);