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

There is no `supabase` CLI link in this repo. Apply migrations by pasting each
file into the target project's SQL editor and running it, **in filename order**:

1. `migrations/20260809000100_create_users.sql` — `public.users`, RLS policies,
   and the `on_auth_user_confirmed` trigger
2. `migrations/20260809000200_email_status.sql` — the `email_status` RPC

Every migration is idempotent (`create table if not exists`,
`create or replace function`, `drop … if exists`, `on conflict do nothing`), so
re-running a file is safe.

Both files are already applied to staging.

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

`public.users` is the source of truth for profile data. It is written by the
`handle_new_user` trigger, which fires **after email confirmation**, not on
signup — so no row exists for an account that was never confirmed.

The trigger swallows every exception on purpose. It runs inside the confirmation
transaction, and raising would make `verifyOTP` fail and lock the user out of the
account being created.

`email_status(p_email text)` returns `'none' | 'unconfirmed' | 'confirmed'` and
is executable by `anon`. It is what lets signup resume an abandoned registration
and lets password reset refuse an unknown address before sending an email.

## Production-readiness gaps

None of these are done, and all are required before production auth works:

- **No SMTP configured.** Without it, no confirmation or recovery email is sent.
- **Both email templates are still the default, link-based ones.** They must be
  converted to `{{ .Token }}` so the 8-digit code is delivered instead of a link.
- **Migrations are not applied.** Both files above must be run against
  `otwasmlfyvytvjbdflpg`.
- **`ANON_KEY` in `lib/env/production/.env` is still a placeholder.** Both env
  files carry `REPLACE_WITH_*_ANON_KEY`; the real publishable keys must be pasted
  in from each project's API settings before the app can reach Supabase at all.
- **`API_URL` must point at the Supabase project.** `Supabase.initialize` reads
  `Env.apiUrl`, so the committed value has to be
  `https://<project-ref>.supabase.co` for the environment being built.

OTP length is 8 in both projects (`mailer_otp_length = 8`); minimum password
length is 6 (`password_min_length`).
