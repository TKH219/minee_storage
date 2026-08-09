create table if not exists public.users (
  id                uuid primary key references auth.users(id) on delete cascade,
  email             text        not null,
  shop_name         text        not null default '',
  is_deactivated    boolean     not null default false,
  last_signed_in_at timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

alter table public.users enable row level security;

drop policy if exists users_select_own on public.users;
create policy users_select_own on public.users
  for select to authenticated
  using (auth.uid() = id);

drop policy if exists users_update_own on public.users;
create policy users_update_own on public.users
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users (id, email, shop_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'shop_name', '')
  )
  on conflict (id) do nothing;
  return new;
exception
  when others then
    -- This runs inside the confirmation transaction. Raising here would make
    -- verifyOTP fail and lock the user out of the account being created.
    return new;
end;
$$;

drop trigger if exists on_auth_user_confirmed on auth.users;
create trigger on_auth_user_confirmed
  after update of email_confirmed_at on auth.users
  for each row
  when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  execute function public.handle_new_user();
