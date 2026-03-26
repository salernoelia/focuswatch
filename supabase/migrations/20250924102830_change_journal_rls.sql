drop policy if exists "all auth users can do all crud operations" on "public"."journals";

create policy "all auth users can do all crud operations"
    on "public"."journals"
    as permissive
    for all
    to authenticated
    using (true)
    with check (true);
