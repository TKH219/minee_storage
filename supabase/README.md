# Supabase

Authentication is owned entirely by Supabase (GoTrue). Product data still flows
through the existing Dio/Retrofit stack, which simply sources its bearer token
from the Supabase session.

## Projects

| Environment | Project ref |
| --- | --- |
| Staging | `hqhgknwhwgvznqhpnxqy` |
| Production | `otwasmlfyvytvjbdflpg` |

**Staging is the only supported environment today.** Production is provisioned
but not configured — see the gaps below.

## Applying migrations

**Migrations are applied by whoever writes them, not handed to a human.** There
is no `supabase` CLI link in this repo and neither `supabase` nor `psql` is
expected to be installed; linking would additionally need a database password
that is not in `.ai/configs/mcp_config.json`.

Instead, POST the SQL to the Management API with the PAT from that config. It
executes as the `postgres` role, which covers all DDL, the `storage.buckets`
insert and the `storage.objects` policies:

```bash
PAT=$(python3 -c "import json;print(json.load(open('.ai/configs/mcp_config.json'))['mcpServers']['supabase_staging']['env']['SUPABASE_ACCESS_TOKEN'])")
REF=hqhgknwhwgvznqhpnxqy   # never otwasmlfyvytvjbdflpg

runsql() {
  python3 -c "import json,sys;print(json.dumps({'query':open(sys.argv[1],encoding='utf-8').read()}))" "$1" \
  | curl -s -X POST "https://api.supabase.com/v1/projects/$REF/database/query" \
      -H "Authorization: Bearer $PAT" -H "Content-Type: application/json" --data-binary @-
}
```

If the `supabase_staging` MCP server is connected to the session, its
`apply_migration` tool is equivalent and records the version for you.

**Record every version.** `supabase_migrations.schema_migrations` exists as of
`20260821000000` and is the only record of what has been applied — the two
2026-08-09 files predate it and were backfilled. After applying a file:

```bash
runq "insert into supabase_migrations.schema_migrations (version, name)
      values ('<version>','<name>') on conflict (version) do nothing"
```

A `201` from the API is not proof the migration did what it meant to. Verify
against `information_schema` and by exercising RLS as a real signed-in user.

### Applied to staging, in order

| Version | What |
| --- | --- |
| `20260809000100` | `public.users`, RLS, the `on_auth_user_confirmed` trigger |
| `20260809000200` | the `email_status` RPC |
| `20260821000000` | `supabase_migrations.schema_migrations`, backfilled |
| `20260821000100` | profile columns on `users`; `handle_new_user` also fires on insert |
| `20260821000200` | `store_categories`, 13 seeded rows, read-only |
| `20260821000300` | `stores`, owner-scoped RLS |
| `20260821000400` | backfill `stores` from `users.shop_name` |
| `20260821000500` | the public `avatars` bucket, uid-scoped writes |
| `20260821000600` | drop `users.shop_name` — **irreversible**, applied last |
| `20260822000100` | `currencies`, 13 seeded rows; `stores.currency` gains a foreign key to it |
| `20260822000200` | `currencies` gains a generated `id`; `stores.currency_id` added and backfilled |
| `20260822000300` | drop `stores.currency` — **irreversible**, applied after the backfill was verified |
| `20260822000400` | `created_at`/`updated_at`/`deleted_at` on every table; `stores.is_archived` dropped in favour of `deleted_at` |
| `20260822001000` | `public.touch_updated_at()` and its triggers on `users` and `stores` — the first trigger of its kind; before this, `updated_at` only ever held the insert time |
| `20260822001100` | backfill the ten applied versions the history table was missing |
| `20260822001200` | `products`, user-scoped RLS, the barcode index that spans archived rows |
| `20260822001300` | `batches`, two-parent RLS, the owner-mismatch trigger, `#B-0001` code sequencing |
| `20260826000100` | `amend_batch` — corrects a delivery, moving the remainder by the same delta |
| `20260822001400` | the public `product-images` bucket, uid-scoped writes |
| `20260822001500` | `apply_consumption` and `product_as_json` — `apply_consumption` dropped again by `20260828000200` |
| `20260822001600` | `list_products` and `list_product_categories` |
| `20260822001700` | `product_store_holdings` |
| `20260827000100` | `transactions` — the ledger header, its check constraints, the partial unique index on `(store_id, code)` and `next_transaction_code` |
| `20260827000200` | `transaction_lines` — the signed delta, the batch/store agreement trigger and the `occurred_at` arrival floor |
| `20260827000300` | `transaction_fees` — and the trigger refusing a fee no type can carry |
| `20260827000400` | `fee_presets` |
| `20260827000500` | seed each store its VAT and Shipping presets |
| `20260827000600` | `compute_transaction_money` — §5.3 in two passes |
| `20260827000700` | `resolve_transaction_payload`, `preview_transaction`, `apply_transaction`, `write_transaction_lines`, `transaction_json` |
| `20260827000800` | `reverse_transaction_lines` and `amend_transaction` |
| `20260827000900` | `remove_transaction` |
| `20260827001000` | `list_transactions` — day-grouped, with whole-day subtotals |
| `20260827001100` | every money and quantity column leaves as a decimal string |
| `20260828000100` | `transaction_lines.quantity_before` — what the lot held when the line was written, so a stock count can show what was counted against what was there |
| `20260828000200` | `apply_consumption` dropped, leaving the ledger as the only server-side write path into a lot |

Every migration is idempotent (`create table if not exists`,
`create or replace function`, `drop … if exists`, `on conflict do nothing`), so
re-running a file is safe. `…000600` is the one exception in spirit: the column
is gone, and it was only applied once this returned zero —

```sql
select count(*) from public.users u
where coalesce(btrim(u.shop_name),'') <> ''
  and not exists (select 1 from public.stores s where s.owner_id = u.id);
```

### Verifying

```bash
# Table reachable; RLS returns nothing to an anonymous caller.
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  "https://hqhgknwhwgvznqhpnxqy.supabase.co/rest/v1/users?select=id&limit=0"

# Returns "none" for an address with no account.
curl -s -X POST -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  -H "Content-Type: application/json" \
  "https://hqhgknwhwgvznqhpnxqy.supabase.co/rest/v1/rpc/email_status" \
  -d '{"p_email":"nobody@example.com"}'
```

## Edge Functions

The products contract in `.ai/contracts/products-api.yaml` cannot be served by
PostgREST: it has its own paths and a `{code, message, data}` envelope. Two
functions adapt the shape.

| Function | Serves |
| --- | --- |
| `products` | everything under `/products/*` — list, create, read, update, archive, restore, categories, barcode lookup, holdings, batch create/update/archive |
| `media` | `POST /media` — multipart image upload into `product-images` |
| `transactions` | the ledger — `/transactions` list and create, `/transactions/preview`, `/transactions/{id}` read, amend and delete, and `/fee-presets` |

Both run on the **caller's** JWT, forwarded to PostgREST, so row-level security
stays the enforcement point and neither function is one. **Neither reads the
service-role key**, and neither should ever be given it: a function holding that
key would silently become the security boundary.

Base URL is `https://<ref>.supabase.co/functions/v1`. The app keeps `Env.apiUrl`
as the bare project URL that `Supabase.initialize` needs and appends the suffix
only for `ProductApi`, because PostgREST and Storage still live at the root.

### Deploying

Neither `deno` nor the `supabase` CLI is installed, so functions deploy through
the Management API. `_shared` files must keep their relative path in the bundle
or the imports will not resolve:

```bash
PAT=$(python3 -c "import json;print(json.load(open('.ai/configs/mcp_config.json'))['mcpServers']['supabase_staging']['env']['SUPABASE_ACCESS_TOKEN'])")
REF=hqhgknwhwgvznqhpnxqy

deploy() {
  name=$1
  curl -s -X POST "https://api.supabase.com/v1/projects/$REF/functions/deploy?slug=$name" \
    -H "Authorization: Bearer $PAT" \
    -F "metadata={\"entrypoint_path\":\"$name/index.ts\",\"name\":\"$name\",\"verify_jwt\":true};type=application/json" \
    -F "file=@supabase/functions/$name/index.ts;filename=$name/index.ts;type=application/typescript" \
    -F "file=@supabase/functions/_shared/envelope.ts;filename=_shared/envelope.ts;type=application/typescript" \
    -F "file=@supabase/functions/_shared/errors.ts;filename=_shared/errors.ts;type=application/typescript" \
    -F "file=@supabase/functions/_shared/client.ts;filename=_shared/client.ts;type=application/typescript"
}
deploy products
deploy media
```

A `201` carrying `"status":"ACTIVE"` means it deployed, not that it works.
There is no local function runtime and no offline test, so the only verification
is `curl` against staging with a real user's JWT:

```bash
ANON=$(curl -s "https://api.supabase.com/v1/projects/$REF/api-keys" -H "Authorization: Bearer $PAT" \
       | python3 -c "import json,sys;print([k['api_key'] for k in json.load(sys.stdin) if k['name']=='anon'][0])")
JWT=$(curl -s -X POST "https://$REF.supabase.co/auth/v1/token?grant_type=password" \
      -H "apikey: $ANON" -H "Content-Type: application/json" \
      -d '{"email":"<test account>","password":"<password>"}' \
      | python3 -c "import json,sys;print(json.load(sys.stdin)['access_token'])")

curl -s -H "apikey: $ANON" -H "Authorization: Bearer $JWT" \
     "https://$REF.supabase.co/functions/v1/products?storeId=<store>"
```

Exercise it with **two** accounts. A route that returns the caller's own data
correctly can still leak someone else's, and only a second token shows that.

## The ledger

Four tables and four RPCs replace the reasonless `apply_consumption`, which
`20260828000200` drops outright. **There is exactly one write path into
`batches.quantity_remaining`, and it is the ledger.** Any other write is a bug.

| Table | What it holds |
| --- | --- |
| `transactions` | the header — type, code, `occurred_at`, counterparty, payment method, and the eleven frozen money columns |
| `transaction_lines` | **a signed `quantity_delta` against one batch**, with the product name, unit and unit cost frozen at write time |
| `transaction_fees` | the resolved fees, each with the amount it moved |
| `fee_presets` | per-store defaults, seeded with VAT 10% pass-through and Shipping |

There is deliberately **no `status` column** and **no `stock_movements` table**.
A transaction is edited and deleted rather than returned and voided, and
`deleted_at` is the only lifecycle state it has.

`quantity_delta` is signed and is the only truth about stock — negative on a
`sale` and `write_off`, positive on a `receive`, either sign on an `adjust`.
Applying is addition and reversing is its negation, computed by the same code,
so nothing in either path branches on the type.

| RPC | What it does |
| --- | --- |
| `compute_transaction_money` | §5.3 in two passes — discounts against `items_subtotal`, everything else against `items_subtotal − discount_total` — rounded half-up to the store currency's minor units **once** |
| `apply_transaction` | resolves the allocation (FEFO), applies every delta, freezes the snapshots, computes the money and inserts. A `receive` creates its batches with landed cost folded in |
| `amend_transaction` | checks the optimistic lock **first**, reverses the existing lines, re-resolves against present stock, soft-deletes the superseded rows, stamps `amended_at` and bumps `revision` |
| `remove_transaction` | checks the lock, reverses the lines, archives a receive's untouched batches, stamps `deleted_at` |
| `preview_transaction` | the same resolution and money, written nowhere — so the previewed total is the stored total |
| `list_transactions` | day-grouped, with each day's subtotal computed over the **whole** day rather than the page slice |

A few rules worth knowing before touching any of it:

- **A `receive` amends its batch in place** and never reverses-and-recreates. It
  is the one type whose lines *create* their batch, so reversing it would strand
  the original lot and open a second for the same delivery. It is refused when
  the new quantity would fall below what has already been drawn out.
- **Landed cost.** Every fee the shop actually bears — `buyer_charge` that is
  not pass-through, less any discount — is apportioned across a receive's lines
  pro-rata by `line_gross` and folded into each lot's `unit_cost`. A
  pass-through fee is excluded: the shop gets it back, so it was never part of
  what the goods cost.
- **Every amend and delete is optimistically locked on `updated_at`.** A stale
  value is refused with `P0010` and **nothing changes**.
- **Later transactions are never replayed.** An amend may therefore land on a
  different batch set than the original, and the UI names that before commit.
- **A code is never released**, including by delete. The unique index is partial
  on `deleted_at is null` and `next_transaction_code` reads the highest ever
  issued rather than counting live rows.

Refusals carry distinct codes so the client can name them: `P0003` insufficient
stock, `P0004` a receive amended below its drawn quantity, `P0005` a date before
the stock arrived, `P0006` a fee the type may not carry, `P0007` a reversal
below zero, `P0008` a reversal above `quantity_received`, `P0009` a lot already
drawn from, `P0010` a stale lock.

## Schema notes

### `products` and `batches`

A product belongs to a **user** and carries identity only — no price, no expiry,
no quantity, no store. A batch belongs to a product **and** a store, and carries
everything that varies per delivery. One catalogue entry therefore serves every
shop its owner runs, and a rename lands in all of them at once.

Two consequences worth knowing before touching either table:

- **The barcode index spans archived rows.** `products(user_id, barcode)` is
  unique where `barcode is not null`, with no `deleted_at` predicate, so an
  archived product keeps its barcode reserved. That is deliberate: it is the
  same physical item, and Restore must never collide with something created
  meanwhile.
- **A batch is authorised through both parents.** The policies check the
  product's `user_id` *and* the store's `owner_id`, and `batches_parents_agree()`
  rejects any row whose two parents have different owners. The policies alone
  would let a caller who owns both file one user's stock against another user's
  shop.

- **`quantity_remaining` is never written from a request body.** It moves only
  through a ledger transaction: a `receive` opens the lot and every later
  movement is a signed delta against it. `apply_consumption` and
  `POST /products/:id/consumptions` are **gone** — the RPC dropped by
  `20260828000200`, the route removed from the products Edge Function — so the
  ledger is the only door, at the server and not only on the device. The one
  exception is `amend_batch`,
  which corrects a delivery rather than moving stock: it shifts the
  remainder by the same delta as `quantity_received` under a row lock, and
  raises `P0004` rather than let a lot fall below what has been drawn out of
  it. Editing a lot is a correction of what arrived, never a statement about
  what is on the shelf.

`batch_code` runs per product **across every store**, so one store's list can
legitimately show `#B-0001`, `#B-0003` with the gap sitting in another shop.


`public.users` is the **profile** table: `full_name`, `avatar_url`,
`onboarding_completed_at`, plus `email`, `is_deactivated` and `last_signed_in_at`.
It carries no shop identity — shops are rows in `public.stores`, and one user
owns many.

It is written by the `handle_new_user` trigger, which fires on two triggers
sharing one function: `on_auth_user_confirmed` (after `email_confirmed_at` goes
null → not-null) and `on_auth_user_created` (after insert, when
`email_confirmed_at` is already set). The second exists for OAuth accounts,
which are inserted already confirmed and so never fire the first. No row exists
for an account that was never confirmed.

The trigger swallows every exception on purpose. It runs inside the confirmation
transaction, and raising would make `verifyOTP` fail and lock the user out of the
account being created.

`public.stores` is owner-scoped: RLS is plain `owner_id = auth.uid()` for all
four commands. There is deliberately no `store_members` table yet — with one
role there is nothing to model, and adding it now would mean a `security
definer` helper to break the recursion between the two tables' policies.

`public.store_categories` and `public.currencies` are both seeded reference
data, readable by `authenticated` and writable by nobody. Note they are keyed
differently: a category is referenced by its natural `code`, a currency by a
generated `id` (`stores.currency_id`), with `currencies.code` kept unique
alongside it. Adding either now needs a migration — the accepted cost of one
source of truth rather than a Dart list that can drift from the column it writes.

Every table carries `created_at`, `updated_at` and `deleted_at`. `deleted_at` is
the soft delete: every read filters `deleted_at=is.null`, and `stores.is_archived`
was dropped in its favour. Note the consequence — a deleted store leaves reports
entirely, where an archived one used to remain readable; if that older meaning is
wanted back it needs a separate flag.

**Every body and every response is a model, not a map.** Reads decode into
`StoreModel`, `StoreCategoryModel`, `CurrencyModel` and `UserModel`, each with a
`toEntity()` that is the only place the domain learns the wire format — the
entities themselves no longer parse JSON. Writes go out as `CreateStoreRequest`,
`UpdateUserRequest` and `EmailStatusRequest`. Nothing on either path is typed
`dynamic` or `Map<String, dynamic>` except the generated `fromJson`/`toJson`
signatures themselves.

**Request bodies are models, not maps.** `POST /rest/v1/stores` takes a
`CreateStoreRequest` (`lib/data/models/request/store/`), serialised by
json_serializable with `fieldRename: FieldRename.snake` so the field names are
the column names by construction rather than by hand-written string keys.
`includeIfNull: false` means an unset optional is omitted rather than sent as
null, so the column keeps its own default.

**Per-request auth.** `SupabaseRestInterceptor` attaches the session token by
default. An endpoint that runs before anyone is signed in opts out:

```dart
@POST('/rest/v1/rpc/email_status')
@Extra({SupabaseRestInterceptor.requiresAuthKey: false})
Future<String> emailStatus(@Body() Map<String, dynamic> body);
```

It then goes out with the anon key as both `apikey` and bearer. This is not
cosmetic: `email_status` is called from signup step 1 and forgot-password, and
PostgREST answers a stale bearer with `401 PGRST301 JWT cryptographic operation
failed` — so a user holding an expired session could not have signed up or reset
their password. The flag defaults to *requiring* auth, so an endpoint keeps its
token unless it deliberately gives it up.

**Both are read over REST, not the Supabase SDK.** Table and storage access goes
through Dio + Retrofit against `/rest/v1` and `/storage/v1` — see
`store_api.dart`, `user_api.dart` and `SupabaseRestInterceptor`, which supplies
the `apikey` header PostgREST requires alongside the bearer. `supabase_flutter`
remains only for auth: credentials, the OTP, and the session. That boundary is
expressed in the types rather than in a comment — `AuthDataSource` is GoTrue
only, `UserProfileDataSource` is REST only, and `AuthRepositoryImpl` holds one
of each. A REST failure
arrives as a `DioException` already carrying a typed `AppException` from
`ErrorInterceptor`, so repositories must **not** re-wrap it — doing so flattens
a network error into "unknown". Its `icon` column holds an opaque token that the app
maps to an icon with a fallback, so a category added later cannot break an
older client.

The `avatars` storage bucket is public-read. Writes are allowed only where the
**second** path segment equals the caller's uid — `users/{uid}/…` and
`stores/{uid}/…`.

`email_status(p_email text)` returns `'none' | 'unconfirmed' | 'confirmed'` and
is executable by `anon`. It is what lets signup resume an abandoned registration
and lets password reset refuse an unknown address before sending an email.

## Production-readiness gaps

None of these are done, and all are required before production auth works:

- **No SMTP configured.** Without it, no confirmation or recovery email is sent.
- **Both email templates are still the default, link-based ones.** They must be
  converted to `{{ .Token }}` so the 6-digit code is delivered instead of a link.
- **Migrations are not applied.** All thirteen files above must be run against
  `otwasmlfyvytvjbdflpg`, in order.
- **`ANON_KEY` in `lib/env/production/.env` is still a placeholder.** Both env
  files carry `REPLACE_WITH_*_ANON_KEY`; the real publishable keys must be pasted
  in from each project's API settings before the app can reach Supabase at all.
- **`API_URL` must point at the Supabase project.** `Supabase.initialize` reads
  `Env.apiUrl`, so the committed value has to be
  `https://<project-ref>.supabase.co` for the environment being built.
- **`mailer_otp_length` is still 8 on production.** The project is paused
  (`status: INACTIVE`) and the Management API rejects config writes against it.
  Resume the project, then set it to 6 — see below.

OTP length is 6, which is what `OtpField.codeLength` renders; a project left at
the old 8 issues codes the field silently truncates, so every verification
fails. Staging is already set. Minimum password length is 6
(`password_min_length`).

```bash
curl -s -X PATCH "https://api.supabase.com/v1/projects/<project-ref>/config/auth" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mailer_otp_length": 6}'
```
