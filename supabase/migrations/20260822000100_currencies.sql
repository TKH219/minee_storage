create table if not exists public.currencies (
  code       text primary key,
  symbol     text not null,
  decimals   int  not null default 2,
  sort_order int  not null
);

alter table public.currencies enable row level security;

drop policy if exists currencies_select on public.currencies;
create policy currencies_select on public.currencies
  for select to authenticated
  using (true);

insert into public.currencies (code, symbol, decimals, sort_order) values
  ('VND', '₫',  0, 10),
  ('USD', '$',  2, 20),
  ('EUR', '€',  2, 30),
  ('JPY', '¥',  0, 40),
  ('KRW', '₩',  0, 50),
  ('THB', '฿',  2, 60),
  ('SGD', 'S$', 2, 70),
  ('MYR', 'RM', 2, 80),
  ('PHP', '₱',  2, 90),
  ('IDR', 'Rp', 0, 100),
  ('CNY', '¥',  2, 110),
  ('AUD', 'A$', 2, 120),
  ('GBP', '£',  2, 130)
on conflict (code) do nothing;

-- Added after the seed so existing stores.currency values validate against it.
alter table public.stores drop constraint if exists stores_currency_fkey;
alter table public.stores
  add constraint stores_currency_fkey
  foreign key (currency) references public.currencies(code);
