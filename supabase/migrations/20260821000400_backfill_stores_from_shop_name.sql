insert into public.stores (owner_id, name, category_code, currency)
select u.id, u.shop_name, 'other', 'VND'
from public.users u
where coalesce(btrim(u.shop_name), '') <> ''
  and not exists (select 1 from public.stores s where s.owner_id = u.id);

update public.users u
set onboarding_completed_at = coalesce(u.onboarding_completed_at, now())
where exists (select 1 from public.stores s where s.owner_id = u.id);
