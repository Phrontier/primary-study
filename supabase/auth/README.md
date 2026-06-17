# Supabase Auth configuration

This folder contains the hosted Auth settings that cannot be represented as a SQL migration.

Run a dry run first:

```sh
node scripts/configure-supabase-auth.mjs --dry-run
```

Apply the standard Primary Gouge settings:

```sh
SUPABASE_ACCESS_TOKEN=... node scripts/configure-supabase-auth.mjs
```

That patches the Supabase Management API for project `nsnezmbmosqtpychvpea` and enables email/password auth, email confirmation, 6-digit OTP templates, password reset OTP templates, password changed/security notifications, and leaked password protection.

Apple Sign in uses the native iOS bundle id by default:

```sh
SUPABASE_ACCESS_TOKEN=... APPLE_CLIENT_ID=bolt.Primary-Gouge node scripts/configure-supabase-auth.mjs
```

If the Supabase Apple provider is configured with an Apple Services ID/OAuth flow, provide the Services ID as `APPLE_CLIENT_ID` or `APPLE_SERVICES_ID`, add the native bundle id to `APPLE_ADDITIONAL_CLIENT_IDS`, and either pass `APPLE_CLIENT_SECRET` or let the script generate one from Apple key material:

```sh
SUPABASE_ACCESS_TOKEN=... \
APPLE_CLIENT_ID=com.example.primary-gouge.web \
APPLE_ADDITIONAL_CLIENT_IDS=bolt.Primary-Gouge \
APPLE_TEAM_ID=... \
APPLE_KEY_ID=... \
APPLE_PRIVATE_KEY_PATH="$HOME/secure/AuthKey_XXXXXXXXXX.p8" \
node scripts/configure-supabase-auth.mjs
```

Never commit Supabase access tokens, Apple `.p8` keys, or generated Apple client secrets.
