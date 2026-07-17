# App Review access

Primary Gouge requires an account. App Review must receive a dedicated,
verified email/password account with a completed profile and Premium access.
Do not commit the review password or paste it into app source code.

## Prepare the account

1. Create and verify a dedicated account through the production app.
2. Complete its profile with a squadron and syllabus so the app does not stop
   at onboarding.
3. In the Supabase SQL editor, grant time-limited review access. Replace the
   email and choose an expiration comfortably beyond the expected review date:

```sql
insert into public.subscription_access_overrides (
  user_id,
  reason,
  is_active,
  expires_at
)
select
  id,
  'app_review',
  true,
  timezone('utc', now()) + interval '90 days'
from auth.users
where lower(email) = lower('REPLACE_WITH_REVIEW_EMAIL')
on conflict (user_id) do update
set reason = excluded.reason,
    is_active = true,
    expires_at = excluded.expires_at,
    updated_at = timezone('utc', now());
```

4. Sign in on a clean device and confirm the Premium screen says
   `Premium is active` and all paid destinations open.
5. Put the account email/password in App Store Connect's App Review
   Information fields, not in this repository.

## Review notes template

Primary Gouge requires sign-in. The supplied demo account has a completed
training profile and server-granted Premium access so App Review can exercise
all user-facing functionality without purchasing. The production auto-renewable
subscription is `bolt.primarygouge.premium.monthly`. The Premium screen also
supports purchase, restore, and Apple subscription management. Instructor
reviews are pre-moderated; reporting and account deletion are available in the
app. Backend services must remain online throughout review.

## Revoke access

After review, disable the override without deleting the reviewer account:

```sql
update public.subscription_access_overrides
set is_active = false,
    updated_at = timezone('utc', now())
where user_id = (
  select id from auth.users
  where lower(email) = lower('REPLACE_WITH_REVIEW_EMAIL')
);
```
