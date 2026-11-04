-- Data API exposure is opt-in for public tables created after 2026-10-30.
-- Grants below match how this app uses each table. RLS still limits rows.

grant select, insert on table public.error_tracking to authenticated;
grant select, insert, update, delete on table public.error_tracking to service_role;
grant execute on function public.set_app_version() to authenticated, service_role;

do $$
begin
  if to_regclass('public.users') is not null then
    execute 'grant select, insert, update on table public.users to authenticated';
    execute 'grant select, insert, update, delete on table public.users to service_role';
  end if;

  if to_regclass('public.expenses') is not null then
    execute 'grant select, insert, update, delete on table public.expenses to authenticated, service_role';
  end if;

  if to_regclass('public.income') is not null then
    execute 'grant select, insert, update, delete on table public.income to authenticated, service_role';
  end if;

  if to_regclass('public.mileage') is not null then
    execute 'grant select, insert, update, delete on table public.mileage to authenticated, service_role';
  end if;

  if to_regclass('public.keepalive_heartbeat') is not null then
    execute 'grant select, insert, delete on table public.keepalive_heartbeat to anon';
  end if;

  if to_regclass('public.keepalive_heartbeat_id_seq') is not null then
    execute 'grant usage, select on sequence public.keepalive_heartbeat_id_seq to anon';
  end if;
end $$;
