# Instructor Reviews Cloudflare Backend

This Worker replaces the direct Supabase path for instructor reviews with a Cloudflare-native stack:

- `Workers` for the API
- `D1` for approved reviews, queued submissions, reports, and moderators
- `Cron Triggers` for scheduled moderation runs
- optional `Workers AI` screening during the scheduled moderation pass

## What it does

- keeps the iOS app offline-first by accepting queued submissions when online
- serves approved reviews back to every device
- lets moderators sign in and work the moderation queue
- runs automatic screening on a schedule instead of on every write to conserve tokens

## Endpoints

- `GET /v1/reviews/published`
- `GET /v1/submissions/statuses`
- `GET /v1/reports/statuses`
- `POST /v1/submissions`
- `POST /v1/reports`
- `POST /v1/moderator/sign-in`
- `POST /v1/moderator/refresh`
- `GET /v1/moderation/queue`
- `POST /v1/moderation/submissions/:id/approve`
- `POST /v1/moderation/submissions/:id/reject`
- `POST /v1/moderation/reports/:id/dismiss`

## Setup

1. Install dependencies:

```bash
npm install
```

2. Create the D1 database:

```bash
npx wrangler d1 create primary-gouge-instructor-reviews
```

3. Paste the returned D1 `database_id` into [wrangler.jsonc](/Users/conwaybolt/Library/CloudStorage/OneDrive-Personal/Documents/Projects/Development/Primary%20Gouge/Cloudflare/InstructorReviewsBackend/wrangler.jsonc).

4. Apply migrations:

```bash
npm run db:migrate:remote
```

5. Add the moderator session secret:

```bash
npx wrangler secret put MODERATOR_SESSION_SECRET
```

6. Create a password hash for each moderator:

```bash
npm run moderator:hash -- 'your-password'
```

The included script uses a Cloudflare-compatible PBKDF2 setting so the Worker can verify the hash at runtime.

7. Insert the moderator row into D1:

```sql
INSERT INTO moderator_accounts (email, password_hash, display_name, is_active, created_at, updated_at)
VALUES (
  'you@example.com',
  'pbkdf2$...generated hash...',
  'Your Name',
  1,
  datetime('now'),
  datetime('now')
)
ON CONFLICT(email) DO UPDATE SET
  password_hash = excluded.password_hash,
  display_name = excluded.display_name,
  is_active = excluded.is_active,
  updated_at = excluded.updated_at;
```

8. Deploy:

```bash
npm run deploy
```

9. Copy the deployed Worker URL into the iOS app config key:

- `INSTRUCTOR_REVIEW_BACKEND_URL`

## Local development

Run the API locally, including scheduled-handler testing:

```bash
npm run dev
```

Then test the scheduled moderation pass:

```bash
curl "http://127.0.0.1:8787/__scheduled?cron=0+*+*+*+*"
```

## Moderation schedule

The Worker runs scheduled moderation weekly by default:

- obvious profanity, slurs, threats, and spam get auto-rejected
- weak or suspicious content gets marked for human review
- clean reviews can be marked `screened_clean`, but they still stay pending until a moderator approves them

That keeps token usage lower than per-submission AI screening, while still reducing junk in the queue.
