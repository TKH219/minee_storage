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

## Schema notes

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
