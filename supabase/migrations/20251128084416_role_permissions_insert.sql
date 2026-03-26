do $$
begin
  if not exists (select 1 from pg_enum e join pg_type t on e.enumtypid = t.oid where t.typname = 'app_permission' and e.enumlabel = 'logs.select') then
    alter type public.app_permission add value 'logs.select';
  end if;
  if not exists (select 1 from pg_enum e join pg_type t on e.enumtypid = t.oid where t.typname = 'app_permission' and e.enumlabel = 'logs.insert') then
    alter type public.app_permission add value 'logs.insert';
  end if;
end $$;

commit;

insert into public.role_permissions (role, permission)
values
  ('admin', 'logs.select'),
  ('user', 'logs.insert');