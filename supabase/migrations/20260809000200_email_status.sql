create or replace function public.email_status(p_email text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_confirmed timestamptz;
begin
  select u.email_confirmed_at
    into v_confirmed
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;

  -- FOUND, not a sentinel variable: SELECT INTO assigns NULL when no row
  -- matches, so a boolean flag would come back NULL rather than false and the
  -- "no account" branch would never fire.
  if not found then
    return 'none';
  end if;

  if v_confirmed is null then
    return 'unconfirmed';
  end if;

  return 'confirmed';
end;
$$;

revoke all on function public.email_status(text) from public;
grant execute on function public.email_status(text) to anon, authenticated;
