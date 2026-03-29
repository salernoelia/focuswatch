grant delete on table "public"."watches" to "postgres";

grant insert on table "public"."watches" to "postgres";

grant references on table "public"."watches" to "postgres";

grant select on table "public"."watches" to "postgres";

grant trigger on table "public"."watches" to "postgres";

grant truncate on table "public"."watches" to "postgres";

grant update on table "public"."watches" to "postgres";


  create policy "Users can read own role"
  on "public"."user_roles"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



